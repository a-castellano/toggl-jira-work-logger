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
use Carp qw(croak);

use Toggl::Wrapper;
use Data::Dumper;

use constant USER_AGENT => "toggl-jira-work-logger";

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

    $request->authorization_basic( "$auth->{user}", "$auth->{password}" );

    # Headers
    if (@$headers) {
        foreach my $header (@$headers) {
            $request->header(%$header);
        }
    }

    # Data
    if (%$data) {
        foreach my $key ( keys %$data ) {
            $json_data = "$json_data \"$key\":$data->{$key},";
        }
        $json_data = substr( $json_data, 0, -1 );
        $json_data = "{$json_data}";
        $request->content($json_data);
    }
    else {
        $request->content("");
        $request->content_length('0');
    }
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
    my ( $url, $user, $password, $issue_code, $time_spent, $comment ) = @_;

    my $response;

    $response = make_api_call(
        {
            type => 'POST',
            url  => join( '', ( $url, '/issue/', $issue_code, '/worklog' ) ),
            auth => {
                user => $user,
                password => $password ,
            },
            headers => [
                { 'Content-Type' => 'application/json' },
                { 'Accept'       => 'application/json' },
            ],
            data => {
                started   => DateTime->now()->iso8601(),
                timeSpent => $time_spent,
                comment   => $comment,
            },
        }
    );

}

#Main

my $jira_url      = $ENV{'JIRA_URL'};
my $jira_email    = $ENV{'JIRA_EMAIL'};
my $jira_user    = $ENV{'JIRA_USER'};
my $jira_password = $ENV{'JIRA_PASSWORD'};

my $toggl_api_token = $ENV{'TOGGL_API_KEY'};

my $issue_code = $ENV{'JIRA_EXAMPLE_ISSUE'};

my $comment = "Test";

work_log( $jira_url, $jira_user, $jira_password, $issue_code, "5m", "Test" );
