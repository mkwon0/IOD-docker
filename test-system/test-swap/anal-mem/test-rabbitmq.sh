#!/bin/bash

#### Parameters
NUM_DEV=4
TEST_TYPE=rabbitmq
NUM_THREAD=1

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme0n1/docker

checker () {
	PID=$(docker inspect --format '{{.State.Pid}}' rabbitmq1)
	grep VmPeak /proc/$PID/status
}

mem_checker() {
	echo "" > stats
	while true; do
		sleep 0.01
		docker stats --no-stream --format "{{.MemUsage}} {{.Name}} {{.Container}}" | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0 }' >> stats
	done
}

pid_waits () {
    PIDS=("${!1}")
    for pid in "${PIDS[*]}"; do
        wait $pid
    done
}

pid_kills() {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		kill -15 $pid
	done
}

docker_remove() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Start removing exisintg docker$(tput sgr 0)"
    docker ps -aq | xargs --no-run-if-empty docker stop
    docker ps -aq | xargs --no-run-if-empty docker rm
}

docker_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing docker engine$(tput sgr 0)"
	DIR=/mnt/nvme0n1/rabbitmq1
	rm -rf $DIR && mkdir -p $DIR
}

docker_rabbitmq_gen() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Generating rabbitmq containers$(tput sgr 0)"
	echo "gen" >> stats
	docker run -itd --name=rabbitmq1 \
	 -v /mnt/nvme0n${DEV_ID}/rabbitmq${CONT_ID}:/var/lib/rabbitmq \
	-e RABBITMQ_DEFAULT_USER=test -e RABBITMQ_DEFAULT_PASS=test \
	-p $HOST_PORT:5672 \
	rabbitmq:3.7.15-management &
	GEN_PID=$!
	wait $GEN_PID
}

docker_rabbitmq_run() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Execute Rabbitmq Benchmark$(tput sgr 0)"
    RABBIT_PIDS=()
    for CONT_ID in $(seq 1 ${NUM_THREAD}); do
        HOST_PORT=$((5671+${CONT_ID}))
        /home/mkwon/src/rabbitmq-perf-test-2.8.1/bin/runjava com.rabbitmq.perf.PerfTest -h amqp://test:test@localhost:${HOST_PORT} --time 2 &> ${INTERNAL_DIR}/output${CONT_ID}.txt & RABBIT_PIDS+=("$!")
    done
    pid_waits RABBIT_PIDS[@]
    sleep 5
}


#### Docker initialization
rm -rf stats
docker_remove
docker_init

mem_checker	&
CHECKER_PID=$!	
docker_rabbitmq_gen
docker_rabbitmq_run
kill -15 $CHECKER_PID
