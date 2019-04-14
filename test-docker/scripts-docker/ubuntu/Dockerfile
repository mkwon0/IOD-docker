FROM ubuntu:18.04

RUN apt-get update && apt-get install apt-utils -y && \
	apt-get install fio -y && \
	apt-get install at -y && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN /etc/init.d/atd start 
