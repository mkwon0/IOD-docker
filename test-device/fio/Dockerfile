FROM ubuntu
ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy 'http://root:camelab0304@192.168.30.200:8080'
ENV https_proxy 'http://root:camelab0304@192.168.30.200:8080'

RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y
RUN apt-get install fio -y

VOLUME /tmp/fio-data
ADD run.sh /opt/run.sh
RUN chmod +x /opt/run.sh
WORKDIR /tmp/fio-data
CMD ["/opt/run.sh"]
