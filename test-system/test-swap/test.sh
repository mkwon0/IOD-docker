#!/bin/bash

#### Parameters
NUM_DEV=4
NUM_THREAD=256

TEST_TYPE=mysql

ARR_SWAP_TYPE=(public)
ARR_IO_TYPE=(oltp_read_only)
#ARR_SWAP_TYPE=(private public)
#ARR_IO_TYPE=(oltp_read_only oltp_write_only)

#### MySQL Parameters
OPTIONS="--threads=1 --events=10000 --time=0 \
         --table-size=1000000 --db-driver=mysql \
         --mysql-host=0.0.0.0 \
         --mysql-user=root --mysql-password=root \
         --mysql-ignore-errors="all" \
         --histogram "

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
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
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

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		if [ -e /mnt/nvme1n${DEV_ID}/swapfile${CONT_ID} ]; then
			swapoff /mnt/nvme1n${DEV_ID}/swapfile${DEV_ID}
		fi
	done

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
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		DIR=/mnt/nvme1n${DEV_ID}/mysql${CONT_ID}
		mkdir -p $DIR
	done
    mkdir -p $DOCKER_ROOT
    systemctl start docker
}

swapfile_private_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing private swapfile$(tput sgr 0)"

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1)) 
		SWAPFILE=/mnt/nvme1n${DEV_ID}/swapfile${CONT_ID}
		dd if=/dev/zero of=$SWAPFILE bs=1M count=1536 # 1.5G
		chmod 600 $SWAPFILE
		mkswap -L swapfile${CONT_ID} $SWAPFILE

		echo "/mnt/nvme1n${DEV_ID}/swapfile${CONT_ID} swap swap defaults,private 0 0" >> /etc/fstab
	done

	swapon -a
	cat /proc/swaps | grep private

	awk '$4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

swapfile_public_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing public swapfile$(tput sgr 0)"

	SWAPFILE=/mnt/nvme1n1/swapfile1
	let SWAPSIZE="1536 * $NUM_THREAD"
	dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAPSIZE
	chmod 600 $SWAPFILE
	mkswap -L swapfile1 $SWAPFILE

	echo "/mnt/nvme1n1/swapfile1 swap swap defaults,private 0 0" >> /etc/fstab

	swapon -a
	cat /proc/swaps | grep private

	awk '$4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

docker_healthy() {
	while [ "$(docker ps -a | grep -c starting)" = 1 ]; do
		sleep 0.1;
	done
}

docker_mysql_gen() {
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		docker run --name=mysql${CONT_ID} \
			--oom-kill-disable=true \
			--memory "80m" --memory-swap -1 \
			--memory-swappiness "100" \
			 -v /mnt/nvme1n${DEV_ID}/mysql${CONT_ID}:/var/lib/mysql \
			-e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% \
			-p $HOST_PORT:3306 -d mysql/mysql-server:8.0
		DID=$(docker inspect mysql${CONT_ID} --format {{.Id}})
		if [ $SWAP_TYPE == "private" ]; then
			DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
			echo /mnt/nvme1n${DEV_ID}/swapfile${CONT_ID} > /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
		else
			echo /mnt/nvme1n1/swapfile1 > /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
		fi
		cat /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
	done
	sleep 20
	docker_healthy
	sleep 30
	
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		docker exec mysql${CONT_ID} mysql -uroot -p'root' -e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest${CONT_ID};"
	done
}

docker_mysql_prepare() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Prepare MySQL$(tput sgr 0)"
	PREPARE_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} prepare & PREPARE_PIDS+=("$!")
	done
	pid_waits PREPARE_PIDS[@]
}

docker_mysql_run() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Execute MySQL$(tput sgr 0)"
	SYSBENCH_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} run &> ${INTERNAL_DIR}/sysbench${CONT_ID}.output & SYSBENCH_PIDS+=("$!")		
	done
	pid_waits SYSBENCH_PIDS[@]
	sleep 5
}

docker_mysql_cleanup() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Cleanup MySQL$(tput sgr 0)"
	CLEAN_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} cleanup & CLEAN_PIDS+=("$!")
	done
	pid_waits CLEAN_PIDS[@]	
	sleep 5
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

		docker_mysql_gen	
		docker_mysql_prepare
		docker_mysql_run
		docker_mysql_cleanup
	done
done
