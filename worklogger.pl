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

    #die Dumper $request;
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
    my ( $url, $email, $user, $password, $issue_code, $time_spent, $comment ) =
      @_;

    my %author;
    $author{self} =
      join( '', ( $url, JIRA_API_SUB_URL, '/user?username=', $user ) );
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
            data => {
                author    => \%author,
                started   => "2018-03-01T21:59:31.190+0000",
                timeSpent => $time_spent,
                comment   => $comment,
            },
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

if ( $argssize != 2 ) {
    print STDERR
"This script only accepts two args, date and rounded time.\n";
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

if ( DateTime->compare( $dates[0], $dates[1] ) == 1 ) {
    die "Start date cannot be greater than end date.";
}
else {
    $dates[1] = $dates[1]->add( days => 1 );
}

my $rounded_time = $ARGV[2];

my $tggl = Toggl::Wrapper->new( api_token => $toggl_api_token );

#get time day by day

my @entries = @{
    $tggl->get_time_entries(
        {
            start => $dates[0],
            stop  => $dates[1]
        }
    )
};

# total work log mut be multiple of $rounded_time
my %totol_work_by_issue;

my @processed_entries;
my @processed_ids;

@processed_entries =
  sort { $a->{id} <=> $b->{id} } @processed_entries;

for my $entry (@entries) {
    if (
        $entry->{'duration'} > 300    # Ignore entries brief than 5 minutes
        and ( !exists $entry->{"tags"}
            or grep { $_ ne "logged" } @{ $entry->{"tags"} } )
      )
    {
        $entry->{"description"} =~ /^([A-Z]*-[0-9]*) /;
        my $issue_id = $1;
        my $duration = int( $entry->{'duration'} / 60 );

        if ( !exists $totol_work_by_issue{$issue_id} ) {
            $totol_work_by_issue{$issue_id} = { total_time => 0 };
        }
        $totol_work_by_issue{$issue_id}{total_time} += $duration;

        print "Issue $entry->{'description'}\n";
        print "\tStarted at $entry->{'start'}\n";
        print "\tEnded at $entry->{'stop'}\n";
        print "\tWith the following duration: $duration minutes.\n";

        print "\tWhat did you do? -> ";
        my $description = <STDIN>;
        print "\n";
        push(
            @processed_entries,
            {
                issue_id    => $issue_id,
                duration    => $duration,
                description => $description,
                time_entry  => $entry,
            }
        );
    }
}

foreach my $key ( keys %totol_work_by_issue ) {

    my $extra_time;

    if ( $totol_work_by_issue{$key}{total_time} % $rounded_time != 0 ) {
        $extra_time =
          ( int( $totol_work_by_issue{$key}{total_time} / $rounded_time ) + 1 )
          * 15 - $totol_work_by_issue{$key}{total_time};
    }
    foreach my $entry (@processed_entries) {
        if ( $entry->{issue_id} eq $key ) {
            $entry->{duration} += $extra_time;
            last;
        }
    }
}

foreach my $entry (@processed_entries) {
    work_log( $jira_url, $jira_email, $jira_user, $jira_password,
        $entry->{issue_id}, $entry->{duration}, $entry->{description} );
}

# Tag logged entries

print "Done";
