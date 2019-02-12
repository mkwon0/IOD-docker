#!/bin/bash

WORKDIR=/root/bench/docker-compose

composeFile=composeFiles/fio-singleNS.yml
export QD=32
export DEV=nvme1n1
export FILE=text1
export PATTERN=read
export BS=4k
export LOG_MSEC=10
export TS_LOG_FILE=
export FIO_LOG_FILE=
docker-compose -f $WORKDIR/$composeFile up --scale fio-multi=2
docker-compose -f $WORKDIR/$composeFile down
