FROM ubuntu:noble
MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

RUN \
 apt-get update -qq && \
 apt-get install -qq -o=Dpkg::Use-Pty=0 -y gnupg ca-certificates wget --no-install-recommends && \
 wget -O - http://packages.windmaker.net/WINDMAKER-GPG-KEY.pub | apt-key add - && \
 apt-get purge -qq -o=Dpkg::Use-Pty=0 -y gnupg wget && \
 apt-get autoremove -qq -o=Dpkg::Use-Pty=0 -y && \
 apt-get autoclean -qq -o=Dpkg::Use-Pty=0 -y && \
 echo "deb http://packages.windmaker.net/ noble main" >> /etc/apt/sources.list && \
 apt-get update -qq && \
 apt-get install -qq -o=Dpkg::Use-Pty=0 -y toggl-jira-work-logger --no-install-recommends && \
 apt-get purge -y --auto-remove && \
 rm -rf /var/lib/apt/lists/*
