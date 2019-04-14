FROM centos:centos7.6.1810
RUN yum update -y && yum install -y fio at && yum clean all
RUN /usr/sbin/atd
COPY ./docker-stat/dockerstat /usr/bin/.
