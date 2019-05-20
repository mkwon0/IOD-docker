#!/bin/bash

#### Parameters
NUM_DEV=2
TEST_TYPE=nginx
RESULT_DIR=/mnt/data/test/cont-${TEST_TYPE} && mkdir -p ${RESULT_DIR}
ARR_NUM_THREAD=(1)
ARR_IO_TYPE=(GET)

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme1n1/docker

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

nvme_format() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Format nvme block devices$(tput sgr 0)"
    for DEV_ID in $(seq 1 4); do
        nvme format /dev/nvme1n${DEV_ID} -n ${DEV_ID} --ses=0
    done
    sleep 1

    FLAG=true
    while $FLAG; do
        NUSE="$(nvme id-ns /dev/nvme1n1 -n 1 | grep nuse | awk '{print $3}')"
        if [[ $NUSE -eq "0" ]]; then
            FLAG=false
            echo "nvme format done"
        fi
    done
    sleep 1
}

nvme_flush() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Flush nvme block devices$(tput sgr 0)"
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        nvme flush /dev/nvme1n${DEV_ID}
    done
}

docker_remove() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Start removing exisintg docker$(tput sgr 0)"
    docker ps -aq | xargs --no-run-if-empty docker stop
    docker ps -aq | xargs --no-run-if-empty docker rm
    systemctl stop docker

    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        if mountpoint -q /mnt/nvme1n${DEV_ID}; then
            umount /mnt/nvme1n${DEV_ID}
        fi
        rm -rf /mnt/nvme1n${DEV_ID}
        mkdir -p /mnt/nvme1n${DEV_ID}
        wipefs --all --force /dev/nvme1n${DEV_ID}
    done
}

docker_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing docker engine$(tput sgr 0)"
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        mkfs.xfs /dev/nvme1n${DEV_ID}
        mount /dev/nvme1n${DEV_ID} /mnt/nvme1n${DEV_ID}
    done

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		let REMAINED="(${CONT_ID} - 1) % 3"
		let DEV_ID="$REMAINED + 2"
		DIR=/mnt/nvme1n${DEV_ID}/nginx${CONT_ID}
		mkdir -p $DIR
	done
    mkdir -p $DOCKER_ROOT
    systemctl start docker
}

docker_nginx_gen() {
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((32769+${CONT_ID}))
		let REMAINED="(${CONT_ID} - 1) % 3"
		let DEV_ID="$REMAINED + 2"
		docker run --name=nginx${CONT_ID} -v /mnt/nvme1n${DEV_ID}/nginx${CONT_ID}:/usr/suare/nginx/html -p ${HOST_PORT}:80 -d nginx:1.16
	done
}

file_gen() {
    echo "$(tput setaf 4 bold)$(tput setab 7)generate files$(tput sgr 0)"
    DD_PIDS=()
    for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		let REMAINED="(${CONT_ID} - 1) % 3"
		let DEV_ID="$REMAINED + 2"
        dd if=/dev/zero of=/mnt/nvme1n${DEV_ID}/nginx${CONT_ID}/file${CONT_ID} count=102400 bs=4096 > /dev/null & DD_PIDS+=("$!")
    done
    pid_waits DD_PIDS[@]
}

docker_info() {
	docker ps --format "{{.ID}}\t{{.Names}}" > ${INTERNAL_DIR}/container.id
	for CONT_ID in $(seq $NUM_THREAD); do
		docker inspect --format {{.GraphDriver.Data.WorkDir}} nginx${CONT_ID} >> ${INTERNAL_DIR}/container.id
	done
}

for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
	for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR
		
		#### Docker initialization
		docker_remove
		nvme_flush
		nvme_format
		docker_init
		docker_nginx_gen
		docker_info	

		#### nginx test preparation
		file_gen
		sync; echo 3 > /proc/sys/vm/drop_caches

		### SYSTAP initilization
		SYSTAP_PIDS=()
		for DEV_ID in $(seq 1 ${NUM_DEV}); do
			/home/mkwon/IOD-docker/systap/monitor-io.stp nvme1n${DEV_ID} &> ${INTERNAL_DIR}/systap-nvme1n${DEV_ID}.log & SYSTAP_PIDS+=("$!") 	
		done
		sleep 10

		#### nginx benchmark (ApacheBench) Run
		APACHEBENCH_PIDS=()
		for CONT_ID in $(seq 1 ${NUM_THREAD}); do
			HOST_PORT=$((32769+${CONT_ID}))
			OUTPUT_PERCENT=${INTERNAL_DIR}/ab${CONT_ID}.percent
			OUTPUT_GNUPLOT=${INTERNAL_DIR}/ab${CONT_ID}.gnudata
			OUTPUT_SUMMARY=${INTERNAL_DIR}/ab${CONT_ID}.summary
			if [[ IO_TYPE -eq "GET" ]]; then
				ab -t 180 -n 100000 -c 1 -s 600 -e $OUTPUT_PERCENT -g $OUTPUT_GNUPLOT http://localhost:${HOST_PORT}/file${CONT_ID} > $OUTPUT_SUMMARY 2>&1 & APACHEBENCH_PIDS+=("$!")
			fi
		done
		pid_waits APACHEBENCH_PIDS[@]
		pid_kills SYSTAP_PIDS[@]
		sleep 5
			
		### SYSTAP initilization
		SYSTAP_PIDS=()
		for DEV_ID in $(seq 1 ${NUM_DEV}); do
			CHECK_DIR=${INTERNAL_DIR}/checkpoint && mkdir -p $CHECK_DIR
			/home/mkwon/IOD-docker/systap/monitor-io.stp nvme1n${DEV_ID} &> ${CHECK_DIR}/systap-nvme1n${DEV_ID}.log & SYSTAP_PIDS+=("$!") 	
		done
		sleep 10

		for CONT_ID in $(seq 1 ${NUM_THREAD}); do
			docker checkpoint create nginx${CONT_ID} checkpoint0 --leave-running 
		done
				
		pid_kills SYSTAP_PIDS[@]
		
	done
done
