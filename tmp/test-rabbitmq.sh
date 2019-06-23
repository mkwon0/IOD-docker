#!/bin/bash

docker run -d --name rabbitmq1 -p 5672:5672 \
	-e RABBITMQ_DEFAULT_USER=test -e RABBITMQ_DEFAULT_PASS=test \
	--restart=unless-stopped rabbitmq:3.7.15-management
