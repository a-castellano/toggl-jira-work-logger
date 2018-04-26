#!/usr/bin/perl

# Álvaro Castellano Vela <https://github.com/a-castellano>

use utf8;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use JSON::Parse ':all';
use JSON;
use DateTime;
use DateTime::Format::Strptime qw(  );
use Date::Calc qw/Delta_Days/;
use Carp qw(croak);
use Try::Tiny;

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

    if ( $issue_visibility ne "" ) {
        $visibility{type}  = "group";
        $visibility{value} = "$issue_visibility";
        $data{visibility}  = \%visibility;
    }

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
                { 'Content-Type' => 'application/json; charset=utf-8' },
                { 'Accept'       => 'application/json; charset=utf-8' },
            ],
            data => \%data,
        }
    );

}

sub process_time_entries{

my $entries = shift;
my $visibility = shift;
my $toggl = shift;
my $rounded_time = shift;

   my @entries = @{ $entries };

    my %total_work_by_issue;
    my @processed_entries;

    for my $entry (@entries) {

        if (
            $entry->{duration} >= 300    # Ignore entries brief than 5 minutes
            and (
                !exists $entry->{tags}    # And entries already logged
                or grep { $_ ne "logged" } @{ $entry->{tags} }
            )
            and exists $entry->{description}
          )
        {

            if ( $entry->{description} =~ /^([A-Z0-9]+-[0-9]+)/ ) {
                my $issue_id = $1;

                my $duration = int( $entry->{'duration'} / 60 );

                if ( !exists $total_work_by_issue{$issue_id} ) {
                    $total_work_by_issue{$issue_id} = { total_time => 0 };
                }
                $total_work_by_issue{$issue_id}{total_time} += $duration;

                # Shows entry info to user
                print "Issue $entry->{description}\n";
                if ( grep { $_ eq "errored" } @{ $entry->{tags} } ) {
                    print
"\t** ERRORED: This issue was already tried to be registered but it failed. **\n";
                }
                print "\tStarted at $entry->{start}\n";
                print "\tEnded at $entry->{stop}\n";
                print "\tWith the following duration: $duration minutes.\n";

                # User must specify what he/she did in every time entry
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
                chomp $issue_visibility;
                if ( $issue_visibility =~ /^\s*$/ ) {
                    $issue_visibility = $visibility;
                }
                if ( $issue_visibility eq "public" ) {
                    $issue_visibility = "";
                }

                # Set time entries duration in full minutes
                $toggl->update_time_entry( $entry,
                    { duration => $duration * 60 } );

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
                        tags             => \@{ $entry->{tags} },
                        issue_visibility => $issue_visibility
                    }
                );
                print "\n";

            }
        }
    }

    #Round time if needed
    foreach my $key ( keys %total_work_by_issue ) {
        my $extra_time = 0;

        # Total time in entry group must be rounded.
        if ( $total_work_by_issue{$key}{total_time} % $rounded_time != 0 ) {
            $extra_time =
              (
                int( $total_work_by_issue{$key}{total_time} / $rounded_time ) +
                  1 ) * 15 -
              $total_work_by_issue{$key}{total_time};
        }
        foreach my $entry (@processed_entries) {

            # If entry has not been tagged as 'errored'
            # It was already been rounded if needed.
            if ( !( grep { $_ eq "errored" } @{ $entry->{tags} } ) ) {
                if ( $entry->{issue_id} eq $key ) {
                    $entry->{duration} += $extra_time;

                   # After updating entry duration, modify rgistered toggl entry
                   # Time entry duration must be specified in secondss
                    $toggl->update_time_entry( $entry->{time_entry},
                        { duration => $entry->{duration} * 60 } );
                    last;
                }

            }
        }
    }

    return @processed_entries;

}


sub log_entries{

my $processed_entries = shift;
my $toggl = shift;
my $jira_url = shift;
my $jira_email = shift;
my $jira_user = shift;
my $jira_password = shift;

   my @processed_entries = @{ $processed_entries };


        my @entry_ids;
        my @failed_ids;
        foreach my $entry (@processed_entries) {
            my $no_errors = 0;
            try {
                work_log(
                    $jira_url,          $jira_email,
                    $jira_user,         $jira_password,
                    $entry->{issue_id}, $entry->{started},
                    $entry->{duration}, $entry->{description},
                    $entry->{issue_visibility}
                );
                $no_errors = 1;
            }
            catch {
                warn
"Detected and error in $entry->{issue_id}: $_ \n\tThis error has been registered in your toggl dashboard.";
                $no_errors = 0;
                push( @failed_ids, int( $entry->{id} ) );
            };
            if ($no_errors) {
                push( @entry_ids, int( $entry->{id} ) );
            }
        }

        print "Done.\n";
        if ( scalar(@entry_ids) > 0 ) {
            $toggl->bulk_update_time_entries_tags(
                {
                    time_entry_ids => \@entry_ids,
                    tags           => ["logged"],
                    tag_action     => "add",
                }
            );
        }
        if ( scalar(@failed_ids) > 0 ) {
            $toggl->bulk_update_time_entries_tags(
                {
                    time_entry_ids => \@failed_ids,
                    tags           => ["errored"],
                    tag_action     => "add",
                }
            );
        }


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
"This script only accepts three args, start date, end date and rounded time.\nYou can also set an optional visibility role.\nBy default, visibility is set to 'public'.\n";
    exit -1;
}

# Provided dates must be valid
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

# Set default visibility, if there is a fourth arg, it will be visibility default value

my $visibility = "public";
$visibility = $ARGV[3] if ( $argssize == 4 );

# All args parsed, count how many days have to be processed

my $number_of_days = $last_date->delta_days($first_date)->days();

# Create toggl instance
my $toggl = Toggl::Wrapper->new( api_token => $toggl_api_token );

my $current_date = $first_date;

# Process entries day by day

do {

    print "Processing entries from ", $current_date->strftime('%Y-%m-%d'), "\n";

    my $next_date = $current_date->clone()->add( days => 1 );

    my @entries = @{
        $toggl->get_time_entries(
            {
                start => $current_date,
                stop  => $next_date,
            }
        )
    };

    @entries =
      sort { $a->{id} <=> $b->{id} } @entries;

    my @processed_entries = process_time_entries(\@entries, $visibility, $toggl, $rounded_time);

    if ( scalar @processed_entries ) {

        print "Sending Worklogs...";

        log_entries(\@processed_entries, $toggl, $jira_url, $jira_email, $jira_user, $jira_password);

        print "Entries logged."

    }
    else {
        print "There was no entries for that date.\n";
    }
    $current_date = $next_date;
} while ( DateTime->compare( $current_date, $last_date ) < 1 );

print "All Done\n";
