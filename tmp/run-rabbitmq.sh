#!/bin/bash

docker run -it --rm --name rabbitmq -p 5672:5672 -e RABBITMQ_DEFAULT_USER=test -e RABBITMQ_DEFAULT_PASS=test rabbitmq:3.7.15-management
