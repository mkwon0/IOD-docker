FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy 'http://root:camelab0304@192.168.30.200:8080'
ENV https_proxy 'http://root:camelab0304@192.168.30.200:8080'

RUN apt-get update && apt-get install fio -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["fio"]
