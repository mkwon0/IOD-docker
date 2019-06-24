#!/bin/bash

#### Parameters
NUM_DEV=4
NUM_THREAD=16

TEST_TYPE=rabbitmq

ARR_SWAP_TYPE=(private)
ARR_IO_TYPE=(simple)

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme0n1/docker

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
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        nvme format /dev/nvme0n${DEV_ID} -n ${DEV_ID} --ses=0
    done
    sleep 1

    FLAG=true
    while $FLAG; do
        NUSE="$(nvme id-ns /dev/nvme0n1 -n 1 | grep nuse | awk '{print $3}')"
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
        nvme flush /dev/nvme0n${DEV_ID}
    done
}

docker_remove() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Start removing exisintg docker$(tput sgr 0)"
	
    docker ps -aq | xargs --no-run-if-empty docker stop
    docker ps -aq | xargs --no-run-if-empty docker rm
    systemctl stop docker

	MAX_THREAD=1024
	for CONT_ID in $(seq 1 ${MAX_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		if [ -e /mnt/nvme0n${DEV_ID}/swapfile${CONT_ID} ]; then
			swapoff /mnt/nvme0n${DEV_ID}/swapfile${CONT_ID}
		fi
	done

    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        if mountpoint -q /mnt/nvme0n${DEV_ID}; then
            umount /mnt/nvme0n${DEV_ID}
        fi
        rm -rf /mnt/nvme0n${DEV_ID}
        mkdir -p /mnt/nvme0n${DEV_ID}
        wipefs --all --force /dev/nvme0n${DEV_ID}
    done
}

docker_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing docker engine$(tput sgr 0)"
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        mkfs.xfs /dev/nvme0n${DEV_ID}
        mount /dev/nvme0n${DEV_ID} /mnt/nvme0n${DEV_ID}
    done

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		DIR=/mnt/nvme0n${DEV_ID}/rabbitmq${CONT_ID}
		mkdir -p $DIR
	done
    mkdir -p $DOCKER_ROOT
    systemctl start docker
}

swapfile_private_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing private swapfile$(tput sgr 0)"

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1)) 
		SWAPFILE=/mnt/nvme0n${DEV_ID}/swapfile${CONT_ID}
		dd if=/dev/zero of=$SWAPFILE bs=1M count=1536 # 1.5G
		chmod 600 $SWAPFILE
		mkswap -L swapfile${CONT_ID} $SWAPFILE

		echo "/mnt/nvme0n${DEV_ID}/swapfile${CONT_ID} swap swap defaults,private 0 0" >> /etc/fstab
	done

	swapon -a
	cat /proc/swaps | grep private

	awk '$4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

swapfile_public_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing public swapfile$(tput sgr 0)"

	SWAPFILE=/mnt/nvme0n1/swapfile1
	let SWAPSIZE="1536 * $NUM_THREAD"
	dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAPSIZE
	chmod 600 $SWAPFILE
	mkswap -L swapfile1 $SWAPFILE

	echo "/mnt/nvme0n1/swapfile1 swap swap defaults,private 0 0" >> /etc/fstab

	swapon -a
	cat /proc/swaps | grep private

	awk '$4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

docker_rabbitmq_gen() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Generating rabbitmq containers$(tput sgr 0)"
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((5671+${CONT_ID}))
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))

		if [ $SWAP_TYPE == "private" ]; then
			docker run -itd --name=rabbitmq${CONT_ID} \
				--oom-kill-disable=true \
				--memory "4m" --memory-swap -1 \
				--memory-swappiness "100" \
				--memory-swapfile "/mnt/nvme0n${DEV_ID}/swapfile${CONT_ID}" \
				 -v /mnt/nvme0n${DEV_ID}/rabbitmq${CONT_ID}:/var/lib/rabbitmq \
				-e RABBITMQ_DEFAULT_USER=test -e RABBITMQ_DEFAULT_PASS=test \
				-p $HOST_PORT:5672 \
				rabbitmq:3.7.15-management 
		else
			docker run -itd --name=rabbitmq${CONT_ID} \
				--oom-kill-disable=true \
				--memory "4m" --memory-swap -1 \
				--memory-swappiness "100" \
				--memory-swapfile "/mnt/nvme0n1/swapfile1" \
				 -v /mnt/nvme0n${DEV_ID}/rabbitmq${CONT_ID}:/var/lib/rabbitmq \
				-e RABBITMQ_DEFAULT_USER=test -e RABBITMQ_DEFAULT_PASS=test \
				-p $HOST_PORT:5672 \
				rabbitmq:3.7.15-management 
		fi
		DID=$(docker inspect rabbitmq${CONT_ID} --format {{.Id}})
		cat /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
	done
	sleep 60
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

for SWAP_TYPE in "${ARR_SWAP_TYPE[@]}"; do
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		RESULT_DIR=/mnt/data/swap-${SWAP_TYPE}/cont-${TEST_TYPE} && mkdir -p ${RESULT_DIR}
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR
		
		#### Docker initialization
		docker_remove
#		nvme_flush
#		nvme_format
		docker_init

		if [ $SWAP_TYPE == "private" ]; then
			swapfile_private_init
		else
			swapfile_public_init
		fi

		docker_rabbitmq_gen
		docker_rabbitmq_run
	done
done
