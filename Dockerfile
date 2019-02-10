FROM ubuntu:bionic
MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

RUN apt-get update -qq
RUN apt-get install -qq -o=Dpkg::Use-Pty=0 -y wget gnupg
RUN wget -O - http://packages.windmaker.net/WINDMAKER-GPG-KEY.pub | apt-key add
RUN echo "deb http://packages.windmaker.net/ any main" > /etc/apt/sources.list.d/windmaker.list
RUN echo "deb [ arch=amd64 ] http://packages.windmaker.net/ bionic main" >> /etc/apt/sources.list.d/windmaker.list
RUN apt-get update -qq
RUN apt-get install -qq -o=Dpkg::Use-Pty=0 -y toggl-jira-work-logger
