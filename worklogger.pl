#!/usr/bin/perl

# Álvaro Castellano Vela <https://github.com/a-castellano>

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use JSON::Parse ':all';
use JSON;
use JIRA::REST;
use DateTime;
use DateTime::Format::Strptime qw(  );
use Date::Calc qw/Delta_Days/;
use Carp qw(croak);

use Toggl::Wrapper;
use Data::Dumper;

use constant USER_AGENT       => "toggl-jira-work-logger";
use constant JIRA_API_SUB_URL => "/rest/api/2";

sub make_api_call {
    my $call      = shift;
    my $auth      = $call->{auth};
    my $headers   = $call->{headers};
    my $data      = $call->{data};
    my $json_data = "";
    my $wrapper   = LWP::UserAgent->new(
        agent      => USER_AGENT,
        cookie_jar => {}
    );

    my $request = HTTP::Request->new( $call->{type} => "$call->{url}" );

    $request->authorization_basic( $auth->{email}, $auth->{password} );

    # Headers
    if (@$headers) {
        foreach my $header (@$headers) {
            $request->header(%$header);
        }
    }

    # Data
    $request->content( encode_json $data);

    my $response = $wrapper->request($request);
    if ( $response->is_success ) {
        $response = $response->decoded_content;
        my $json = parse_json($response);
        return $json;
    }
    else {
        my $r       = HTTP::Response->parse( $response->status_line );
        my $code    = $r->code;
        my $message = $r->message;
        if ( $code == 403 ) {
            croak "Check your credentaials: API call returned $code: $message";
        }
        else {
            croak "An error ocurred: API call returned $code: $message";
        }
    }
}

sub work_log {
    my (
        $url,        $email,      $user,
        $password,   $issue_code, $started,
        $time_spent, $comment,    $issue_visibility
    ) = @_;

    my %author;
    $author{self} =
      join( '', ( $url, JIRA_API_SUB_URL, '/user?username=', $user ) );

    my %visibility;

    my %data = (
        author    => \%author,
        started   => $started,
        timeSpent => $time_spent,
        comment   => $comment,
    );

    print "\nVISI ->  $issue_visibility\n";

#    if ( $issue_visibility ne "" ) {
        $visibility{type}  = "group";
        $visibility{value} = "$issue_visibility";
        $data{visibility}  = \%visibility;
#    }

    my $response;

    $response = make_api_call(
        {
            type => 'POST',
            url  => join( '',
                ( $url, JIRA_API_SUB_URL, '/issue/', $issue_code, '/worklog' )
            ),
            auth => {
                email    => $email,
                password => $password,
            },
            headers => [
                { 'Content-Type' => 'application/json' },
                { 'Accept'       => 'application/json' },
            ],
            data => \%data,
        }
    );

}

#Main

#Get environment variables

my $jira_url      = $ENV{'JIRA_URL'};
my $jira_email    = $ENV{'JIRA_EMAIL'};
my $jira_user     = $ENV{'JIRA_USER'};
my $jira_password = $ENV{'JIRA_PASSWORD'};

my $toggl_api_token = $ENV{'TOGGL_API_KEY'};

# Process args
my $argssize;
my @args;

my @dates;    #start_date - stop_data

$argssize = scalar @ARGV;

if ( $argssize != 3 and $argssize != 4 ) {
    print STDERR
"This script only accepts three args, start date, end date and rounded time. You can also set an optional visibility role.\n";
    exit -1;
}

for my $arg ( @ARGV[ 0 .. 1 ] ) {
    my ( $y, $m, $d ) = $arg =~ /^([0-9]{4})-([0-1][0-9])-([0-3][0-9])\z/
      or die "$arg is not a valid data.";

    push(
        @dates,
        DateTime->new(
            year      => $y,
            month     => $m,
            day       => $d,
            time_zone => 'local',
        )
    );
}

my $first_date = $dates[0];
my $last_date  = $dates[1];

if ( DateTime->compare( $first_date, $last_date ) == 1 ) {
    die "Start date cannot be greater than end date.";
}

my $rounded_time = $ARGV[2];

my $visibility = "public";
$visibility = $ARGV[3] if ( $argssize == 4 );

my $number_of_days = $last_date->delta_days($first_date)->days();

my $tggl = Toggl::Wrapper->new( api_token => $toggl_api_token );

my $current_date = $first_date;

# Process entries day by day

do {

    print "Processing entries from ", $current_date->strftime('%Y-%m-%d'), "\n";

    my $next_date = $current_date->clone()->add( days => 1 );

    my @entries = @{
        $tggl->get_time_entries(
            {
                start => $current_date,
                stop  => $next_date,
            }
        )
    };

    # total work log mut be multiple of $rounded_time
    my %total_work_by_issue;

    my @processed_entries;
    my @processed_ids;

    @processed_entries =
      sort { $a->{id} <=> $b->{id} } @processed_entries;

    for my $entry (@entries) {
        if (
            $entry->{duration} > 300    # Ignore entries brief than 5 minutes
            and ( !exists $entry->{tags}
                or grep { $_ ne "logged" } @{ $entry->{tags} } )
            and exists $entry->{description}
          )
        {
            if ( $entry->{description} =~ /^([A-Z]*-[0-9]*) / ) {
                my $issue_id = $1;

                my $duration = int( $entry->{'duration'} / 60 );

                if ( !exists $total_work_by_issue{$issue_id} ) {
                    $total_work_by_issue{$issue_id} = { total_time => 0 };
                }
                $total_work_by_issue{$issue_id}{total_time} += $duration;

                print "Issue $entry->{description}\n";
                print "\tStarted at $entry->{start}\n";
                print "\tEnded at $entry->{stop}\n";
                print "\tWith the following duration: $duration minutes.\n";

                my $description = "";
                do {
                    print "\tWhat did you do? -> ";
                    $description = <STDIN>;
                    print "\n";
                    if ( $description =~ /^\s*$/ ) {
                        print
"\nYou Must provide a description for each time entry!\n";
                    }
                } while ( $description =~ /^\s*$/ );

                print "\tSet visibility (default is $visibility):";
                my $issue_visibility = <STDIN>;
                if (   $issue_visibility =~ /^\s*$/ or $issue_visibility eq $visibility )
                {
                    $issue_visibility = $visibility;
                }

                push(
                    @processed_entries,
                    {
                        issue_id => $issue_id,
                        started  => $entry->{start} =~
                          s/\+(\d\d):(\d\d$)/\.0\+$1$2/gr,
                        duration         => $duration,
                        description      => $description,
                        time_entry       => $entry,
                        id               => $entry->{id},
                        issue_visibility => $issue_visibility
                    }
                );

            }
        }
    }

    foreach my $key ( keys %total_work_by_issue ) {

        my $extra_time = 0;

        if ( $total_work_by_issue{$key}{total_time} % $rounded_time != 0 ) {
            $extra_time =
              (
                int( $total_work_by_issue{$key}{total_time} / $rounded_time ) +
                  1 ) * 15 -
              $total_work_by_issue{$key}{total_time};
        }
        foreach my $entry (@processed_entries) {
            if ( $entry->{issue_id} eq $key ) {
                $entry->{duration} += $extra_time;
                last;
            }
        }
    }

    if ( scalar @processed_entries ) {
        print "Sending Worklogs...";
        my @entry_ids;
        foreach my $entry (@processed_entries) {
            work_log(
                $jira_url,          $jira_email,
                $jira_user,         $jira_password,
                $entry->{issue_id}, $entry->{started},
                $entry->{duration}, $entry->{description},
                $entry->{issue_visibility}
            );
            push( @entry_ids, int( $entry->{id} ) );
        }

        print "Done.\n";
        $tggl->bulk_update_time_entries_tags(
            {
                time_entry_ids => \@entry_ids,
                tags           => ["logged"],
                tag_action     => "add",
            }
        );

        print "Entries logged."

    }
    else {
        print "There was no entries for that date.\n";
    }
    $current_date = $next_date;
} while ( DateTime->compare( $current_date, $last_date ) < 1 );

print "All Done\n";
