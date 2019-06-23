#!/bin/bash

NUM_THREAD=2

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

for CONT_ID in $(seq 1 ${NUM_THREAD}); do
	docker network rm perf-test${CONT_ID}
	docker network create perf-test${CONT_ID}

	HOST_PORT=$((15671+${CONT_ID}))
	docker run -itd --network perf-test${CONT_ID} \
		--name rabbitmq${CONT_ID} -p ${HOST_PORT}:15672 \
		rabbitmq:3.7.15-management
	sleep 10
		
	docker run -itd --network perf-test${CONT_ID} \
		--name rabbitmq-bench${CONT_ID} \
		--mount type=bind,source=/mnt/data,target=/mnt/data \
		pivotalrabbitmq/perf-test:latest \
		--uri amqp://rabbitmq${CONT_ID} --time 2 -o /mnt/data/output${CONT_ID}.txt
done
