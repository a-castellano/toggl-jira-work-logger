FROM ubuntu:bionic
MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

RUN apt-get update -qq && apt-get install -qq -o=Dpkg::Use-Pty=0 -y gnupg ca-certificates --no-install-recommends && rm -rf /var/lib/apt/lists/*
COPY repo/windmaker.list /etc/apt/sources.list.d/windmaker.list
COPY repo/WINDMAKER-GPG-KEY.pub /tmp/WINDMAKER-GPG-KEY.pub
RUN apt-key add /tmp/WINDMAKER-GPG-KEY.pub
ARG CACHE_TS=default_ts
RUN apt-get update -qq
RUN apt-get install -qq -o=Dpkg::Use-Pty=0 -y toggl-jira-work-logger --no-install-recommends && rm -rf /var/lib/apt/lists/*
