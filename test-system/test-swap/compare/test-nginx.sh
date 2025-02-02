#!/bin/bash

#### Parameters
NUM_DEV=4
NUM_THREAD=64

TEST_TYPE=nginx

ARR_SWAP_TYPE=(private public)
ARR_IO_TYPE=(GET)

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
		DIR=/mnt/nvme0n${DEV_ID}/nginx${CONT_ID}
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
		dd if=/dev/zero of=$SWAPFILE bs=1M count=1024 # 1.5G
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
	let SWAPSIZE="1024 * $NUM_THREAD"
	dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAPSIZE
	chmod 600 $SWAPFILE
	mkswap -L swapfile1 $SWAPFILE

	echo "/mnt/nvme0n1/swapfile1 swap swap defaults,private 0 0" >> /etc/fstab

	swapon -a
	cat /proc/swaps | grep private

	awk '$4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

docker_nginx_gen() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Generating nginx containers$(tput sgr 0)"
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((32769+${CONT_ID}))
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))

		if [ $SWAP_TYPE == "private" ]; then
			docker run -itd --name=nginx${CONT_ID} \
				--oom-kill-disable=true \
				--memory "4m" --memory-swap -1 \
				--memory-swappiness "100" \
				--memory-swapfile "/mnt/nvme0n${DEV_ID}/swapfile${CONT_ID}" \
				 -v /mnt/nvme0n${DEV_ID}/nginx${CONT_ID}:/usr/share/nginx/html \
				-p $HOST_PORT:80 \
				nginx:1.16
		else
			docker run -itd --name=nginx${CONT_ID} \
				--oom-kill-disable=true \
				--memory "4m" --memory-swap -1 \
				--memory-swappiness "100" \
				--memory-swapfile "/mnt/nvme0n1/swapfile1" \
				 -v /mnt/nvme0n${DEV_ID}/nginx${CONT_ID}:/usr/share/nginx/html \
				-p $HOST_PORT:80 \
				nginx:1.16
		fi
		DID=$(docker inspect nginx${CONT_ID} --format {{.Id}})
		cat /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
	done
	sleep 60
}

docker_nginx_run() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Execute Apache Benchmark$(tput sgr 0)"
	APACHEBENCH_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((32769+${CONT_ID}))
		OUTPUT_SUMMARY=${INTERNAL_DIR}/ab${CONT_ID}.summary
		ab -t 60 -n 100000 -c 1 -s 6000 http://localhost:${HOST_PORT}/file${CONT_ID} > $OUTPUT_SUMMARY 2>&1 & APACHEBENCH_PIDS+=("$!")
	done
	pid_waits APACHEBENCH_PIDS[@]
}

file_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)generate files$(tput sgr 0)"
	DD_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		dd if=/dev/zero of=/mnt/nvme0n${DEV_ID}/nginx${CONT_ID}/file${CONT_ID} count=1M bs=1024 > /dev/null & DD_PIDS+=("$!")
	done
	pid_waits DD_PIDS[@]
	sync; echo 3 > /proc/sys/vm/drop_caches
}

for SWAP_TYPE in "${ARR_SWAP_TYPE[@]}"; do
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		RESULT_DIR=/mnt/data/swap-${SWAP_TYPE}/cont-${TEST_TYPE} && mkdir -p ${RESULT_DIR}
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR
		
		#### Docker initialization
		docker_remove
		nvme_flush
		nvme_format
		docker_init

		if [ $SWAP_TYPE == "private" ]; then
			swapfile_private_init
		else
			swapfile_public_init
		fi

		file_gen
		
		docker_nginx_gen
		docker_nginx_run
	done
done
