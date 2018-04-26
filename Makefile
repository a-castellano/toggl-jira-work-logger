PROG=toggl-jira-work-logger

prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
mandir = $(sharedir)/man
man1dir = $(mandir)/man1

install:
	install -m 0755 $(PROG) $(DESTDIR)$(bindir)/$(PROG)
