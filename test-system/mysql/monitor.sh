#!/bin/bash

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

docker network create network0

docker run -d --name datadog-agent \
	--network network0 \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-v /proc/:/host/proc/:ro \
	-v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
	-e DD_API_KEY=bc0f96d66a2753769633c9175794536b \
	-e DD_APM_ENABLED=true \
	-e DD_APM_NON_LOCAL_TRAFFIC=true \
	datadog/agent:latest

docker run -d --name mysql1 \
	--network network0 \
	-v /mnt/nvme0n1/mysql:/var/lib/mysql \
	-e MYSQL_ROOT_PASSWORD=root \
	-e MYSQL_ROOT_HOST=% \
	-p 3306:3306 \
	-d mysql/mysql-server:8.0
