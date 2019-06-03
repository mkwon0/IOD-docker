#!/bin/bash

#docker run -it --rm pivotalrabbitmq/perf-test:latest --help

docker network create perf-test
docker run -it --rm --network perf-test --name rabbitmq -p 15672:15672 rabbitmq:3.7.8-management
docker run -it --rm --network perf-test pivotalrabbitmq/perf-test:latest --uri amqp://rabbitmq
