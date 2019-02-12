FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy 'http://root:camelab0304@192.168.30.200:8080'
ENV https_proxy 'http://root:camelab0304@192.168.30.200:8080'

RUN rm -rf /etc/apt/sources.list
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt xenial main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb-src mirror://mirrors.ubuntu.com/mirrors.txt xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt xenial-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get install fio -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
