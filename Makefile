PROG=toggl-jira-work-logger
SCRIPT_NAME=worklogger.pl

prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
mandir = $(sharedir)/man
man1dir = $(mandir)/man1

install:
	install -m 0755 $(SCRIPT_NAME) $(DESTDIR)$(bindir)/$(PROG)
