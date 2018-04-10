# toggl-jira-work-logger
Utility to log work into Jira issues using Toggl recorded time entries.

## Why I wrote this utility?

Every day at IT department I have to handle many issues. For each issue, head of department asks us to log your work in Company's JIRA account.

We have to set the following info:
* Date started
* Time spent
* A comment describing what we did during that time.

Also, sometimes, servers come down or a client or our Account Manager scales other issue which has more priority. I have to stop what I'm doing to handle that issue. IT support... you know.

After few days working in this company I realized that we were spent so many minutes a day logging what we were doing so I have try to make that process as fast as possible.

There is a [Toggl Integration with JIRA](https://toggl.com/jira-time-tracking/) which works actually fine. Any time I push the button a time entry is created in my toggl account, this entry has a subject composeb by issue code (WORK-34 for example) and issue description. That integration allows me to know how many time I'm spending in every issue.

But...I wanted to go depper, I wanted to parse time entries and work my work without going to each issue JIRA page, this process was too long and boring.

I wrote a [Wrapper able to manage Toggl time entries using its API](https://github.com/a-castellano/Toggl-Wrapper) and this utility.

## Usage

**worklogger.pl** will use your toggl and JIRA accounts and users. You have to set the following environment variables before start using this utility.

* **JIRA_URL** - Your Organization JIRA url.
* **JIRA_EMAIL** - The e-mail that you use to log in your Organization JIRA accunt. 
* **JIRA_USER** - Your username
* **JIRA_PASSWORD** - Your Password
* **TOGGL_API_KEY** - Your [Toggl API token](https://support.toggl.com/api-token/)

**worklogger.pl** needs three arguments to work
* Start Date.
* End Date.
* Rounded time (for each issue, total time of entries will be rounded to that time).

Optionaly your are able to set a default visibility group for your logs, by default this field is empyty so visibility value is *public*. The visibility groups are has to have the same name that they have in your JIRA board.

Let's see some examples:
```bash
perl worklogger.pl 2018-04-05 2018-04-05 15
Processing entries from 2018-04-05
Issue IT-761 Found error on in my app
	Started at 2018-04-05T16:22:48+00:00
	Ended at 2018-04-05T16:30:01+00:00
	With the following duration: 7 minutes.
	What did you do? -> Fix some issues

	Set visibility (default is public):

Issue IT-762 Test issue
	Started at 2018-04-05T16:30:15+00:00
	Ended at 2018-04-05T16:38:52+00:00
	With the following duration: 8 minutes.
	What did you do? -> Customer issues

	Set visibility (default is public):it-team

Issue IT-762 Test issue
	Started at 2018-04-05T16:38:57+00:00
	Ended at 2018-04-05T17:45:03+00:00
	With the following duration: 66 minutes.
	What did you do? -> OH, there was another bug.

	Set visibility (default is public):developers

Sending Worklogs...Done.
Entries logged.All Done
```

You are also able to set another default visibility team:
```bash
perl worklogger.pl 2018-04-05 2018-04-05 15 developers
```
Finally, each logged time entry is marked as "logged" in your toggl dashboard and it won't be logged again:
```bash
perl worklogger.pl 2018-04-03 2018-04-04 15
Processing entries from 2018-04-03
There was no entries for that date.
Processing entries from 2018-04-04
There was no entries for that date.
All Done
```
