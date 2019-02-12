FROM ubuntu:19.04

ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy 'http://192.168.30.200:8080'
ENV https_proxy 'http://192.168.30.200:8080'

RUN apt-get update && \
    apt-get install -y make pbuilder python-mock python-configobj cdbs devscripts build-essential \
                        git fio
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp
RUN wget http://kr.archive.ubuntu.com/ubuntu/pool/universe/p/python-support/python-support_1.0.15_all.deb
RUN dpkg -i python-support_1.0.15_all.deb

RUN git clone https://github.com/python-diamond/Diamond
RUN cd Diamond && git checkout v3.4 && make deb
RUN dpkg -i Diamond/build/diamond_3.4.0_all.deb
RUN cp /etc/diamond/diamond.conf.example /etc/diamond/diamond.conf

ADD run.sh /opt/run.sh
RUN chmod +x /opt/run.sh
CMD ["/opt/run.sh"]
