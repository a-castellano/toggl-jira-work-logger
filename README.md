# toggl-jira-work-logger
Utility to log work into Jira issues using Toggl recorded time entries.

[Actual Repo](https://git.windmaker.net/a-castellano/toggl-jira-work-logger)

## Why I wrote this utility?

Every day at IT department I have to handle many issues. For each issue, head of department asks us to log our work in Company's JIRA account.

We have to set the following info:
* Date started
* Time spent
* A comment describing what we did during that time.

Sometimes, servers come down or a client or our Account Manager scales other issue which has more priority. I have to stop what I'm doing to handle that issue. IT support... you know.

After few days working in this company I realized that we were spent so many minutes a day logging what we were doing so I tried to make that process as fast as possible, in my commute time of course.

There is a [Toggl Integration with JIRA](https://toggl.com/jira-time-tracking/) which works actually fine. Any time I push the button a time entry is created in my toggl account, this entry has a subject composed by issue code (WORK-34 for example) and issue description. That integration allows me to know how many time I'm spending in every issue.

But...I wanted to go depper, I wanted to parse time entries and work my work without going to each issue JIRA page, this process was too long and boring.

I wrote a [Wrapper able to manage Toggl time entries using its API](https://git.windmaker.net/a-castellano/Toggl-Wrapper) and this utility.

## Ways to use this app

There are two ways to run this app, using the CLI command or using [this project Docker image](https://cloud.docker.com/u/acastellano/repository/docker/acastellano/toggl-jira-work-logger).

Usage is almost the same for these ways, differences will be explained below.

## Installation

### Install from repository (Tested on Ubuntu Xenial and Bionic only)

As I said before this script uses another Perl library from my own. If you are using Ubuntu Xenial or Bionic there is a package available which includes all dependencies:
```bash
wget -O - https://packages.windmaker.net/WINDMAKER-GPG-KEY.pub | sudo apt-key add -
sudo add-apt-repository "deb [ arch=amd64 ] http://packages.windmaker.net/ $(lsb_release -cs) main
sudo add-apt-repository "deb [ arch=amd64 ] http://packages.windmaker.net/ any main"
sudo apt-get update
sudo apt-get install toggl-jira-work-logger
```

### Install from source

After installing [Toggl Wrapper Library](https://git.windmaker.net/a-castellano/Toggl-Wrapper), calling toggl-jira-work-logger should work.

### Docker

There is also a [Docker Image](https://hub.docker.com/r/acastellano/toggl-jira-work-logger), usage will be explained later.

## Usage

**toggl-jira-work-logger** will use your toggl and JIRA accounts and users. You can to set the following environment variables before start using this utility. Those variables values can be set as argumments.

* **JIRA_URL** - Your Organization JIRA url.
* **JIRA_EMAIL** - The e-mail that you use to log in your Organization JIRA account.
* **JIRA_USER** - Your username
* **JIRA_PASSWORD** - Your Password
* **TOGGL_API_KEY** - Your [Toggl API token](https://support.toggl.com/api-token/)
* ROUNDED_TIME - Round tasks time to this number of minutes (default is 0, time won't be changed)
* VISIBILITY_OWNER - You are able to show JIRA work logs and comments only to certain groups or roles. Leaving empty this value mens that your comment will be public. Allowed values are role or group.
* VISIBILITY_OWNER_NAME - If visibility owner has been set you must set the group/role's name, Developers for example..

**Warning!** If you are using Docker you must include TZ environment variable to let the Docker Container know in which timezone we are. 

For example, place the following content at **$HOME/.toggl-jira**
```
TZ=Europe/Madrid
JIRA_URL=https://company.atlassian.net
JIRA_EMAIL=alvaro.castellano.vela@gmail.com
JIRA_USER=a-castellano
JIRA_PASSWORD=Y0UR_J1Ra_Pa55W0RD
TOGGL_API_KEY=yourtogglapitoken
ROUNDED_TIME=15
VISIBILITY_OWNER=role
VISIBILITY_OWNER_NAME=Developers
```

Include a line containing `export $(grep -v '^#' ~/.toggl-jira | xargs -d '\n')` in your bashrc if you are using the CLI.

**toggl-jira-work-logger** needs three arguments to work
* Start Date.
* End Date.

Optionaly your are able to set a default visibility group or role for your logs, by default these fields are empyty so visibility value is *public*. The visibility groups and roles has to have the same name that they have in your JIRA board.

Let's see some examples:
```bash
toggl-jira-work-logger --start-date=2018-04-05 --end-date=2018-04-05 --rounded-time=15
Processing entries from 2018-04-05
Issue IT-761 Found error on in my app
	Started at 2018-04-05T16:22:48+00:00
	Ended at 2018-04-05T16:30:01+00:00
	With the following duration: 7 minutes.
	What did you do? -> Fix some issues

	Set visibility (default is  public)
	Role or group (leave empty if you do not want to change it):

	Role or group (leave empty if you do not want to change it):

Issue IT-762 Test issue
	Started at 2018-04-05T16:30:15+00:00
	Ended at 2018-04-05T16:38:52+00:00
	With the following duration: 8 minutes.
	What did you do? -> Customer issues

	Set visibility (default is  public)
	Role or group (leave empty if you do not want to change it): role

	Role or group (leave empty if you do not want to change it): it-team

Issue IT-762 Test issue
	Started at 2018-04-05T16:38:57+00:00
	Ended at 2018-04-05T17:45:03+00:00
	With the following duration: 66 minutes.
	What did you do? -> OH, there was another bug.
	
	Set visibility (default is  public)
	Role or group (leave empty if you do not want to change it): group

	Role or group (leave empty if you do not want to change it): developers


Sending Worklogs...Done.
Entries logged.
All Done.
```

You are also able to set another default visibility team:
```bash
toggl-jira-work-logger --start-date=2018-04-05 --end-date=2018-04-05 --rounded-time=15 --visibility-owner=role --visibility-owner-name=Developers
```
Finally, each logged time entry is marked as "logged" in your toggl dashboard and it won't be logged again:
```bash
toggl-jira-work-logger --start-date=2018-04-03 --end-date=2018-04-04 --rounded-time=15
Processing entries from 2018-04-03
There was no entries for that date.
Processing entries from 2018-04-04
There was no entries for that date.
All Done
```

**Errored entries**

Sometimes you know....we misspell our visibility team name. If there is some error logging our entry it will be tagged as "errored", next time we run the script, these entry will be processed again (It has already been rounded if it was necessary)

```bash
toggl-jira-work-logger --start-date=2018-04-17 --end-date=2018-04-17 --rounded-time=15 --visibility-owner=role --visibility-owner-name=Developers
Processing entries from 2018-04-17
Issue IT-762 Test Issue
	Started at 2018-04-17T04:37:40+00:00
	Ended at 2018-04-17T04:48:40+00:00
	With the following duration: 11 minutes.
	What did you do? -> Rewrite module.

        Set visibility (default is role developers)
	Role or group (leave empty if you do not want to change it): role
	Role or group name (leave empty if you do not want to change it): developersssss

Detected and error in IT-762: An error ocurred: API call returned 400: Bad Request at worklogger.pl line 276.

	This error has been registered in your toggl dashboard. at worklogger.pl line 272, <STDIN> line 8.
Sending Worklogs...Done.
Entries logged.All Done

toggl-jira-work-logger --start-date=2018-04-17 --end-date=2018-04-17 --rounded-time=15 --visibility-owner=role --visibility-owner-name=Developers
Processing entries from 2018-04-17
Issue IT-762 Test Issue
	** ERRORED: This issue was already tried to be registered but it failed. **
	Started at 2018-04-17T04:37:40+00:00
	Ended at 2018-04-17T04:48:40+00:00
	With the following duration: 11 minutes.
	What did you do? -> Rewrite module.

	Set visibility (default is role developers)
	Role or group (leave empty if you do not want to change it): 
	
	Role or group name (leave empty if you do not want to change it):

Sending Worklogs...Done.
Entries logged.
All Done
```

### Docker usage

Call this utility with `docker run`, behaviour will be the same as above.
```bash
docker run --rm  -it  --env-file=$HOME/.toggl-jira acastellano/toggl-jira-work-logger toggl-jira-work-logger 2019-02-02 2019-02-02 15 role Developers
```

