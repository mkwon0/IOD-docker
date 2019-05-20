#!/bin/bash

docker stop cr && docker rm cr
docker run --security-opt=seccomp:unconfined --name cr -d busybox /bin/sh -c 'i=0; while true; do echo $i; i=$(expr $i + 1); sleep 1; done'
docker checkpoint create --leave-running=true cr checkpoint0
