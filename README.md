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

