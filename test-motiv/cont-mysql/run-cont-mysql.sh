#!/bin/bash

#### Parameters
NUM_DEV=4
#RESULT_DIR=/mnt/data/motiv/cont-mysql/NS${NUM_DEV}
RESULT_DIR=/mnt/data/inotify/cont-mysql/NS${NUM_DEV}
#ARR_NUM_THREAD=(4 16 64 256)
#ARR_IO_TYPE=(oltp_read_only oltp_write_only)
ARR_NUM_THREAD=(4)
ARR_IO_TYPE=(oltp_read_only oltp_write_only)

for i in $(seq 1 ${NUM_DEV}); do
	DEV_ID=$((${NUM_DEV}-$i+1))
	ARR_DEV_ID+=(${DEV_ID})
done

#### MySQL Parameters
OPTIONS="--threads=1 --events=10000 --time=0 \
         --table-size=1000000 --db-driver=mysql \
         --mysql-host=0.0.0.0 \
         --mysql-user=root --mysql-password=root \
         --mysql-ignore-errors="all" \
         --histogram "

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme1n1p1/docker

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

delPart() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Delete existing nvme partition$(tput sgr 0)"
    for DEV_ID in $(seq 1 4); do
        echo -e "d\nw" | fdisk /dev/nvme1n${DEV_ID}
    done
}

genPart() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Regenerate nvme partition$(tput sgr 0)"
    SIZE=$((400/${NUM_DEV}))
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        echo -e "o\nn\np\n1\n\n+${SIZE}G\nw" | fdisk /dev/nvme1n${DEV_ID}
    done
    sleep 3
}

nvme_format() {
    delPart
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
    genPart
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
        if mountpoint -q /mnt/nvme1n${DEV_ID}p1; then
            umount /mnt/nvme1n${DEV_ID}p1
        fi
        rm -rf /mnt/nvme1n${DEV_ID}p1
        mkdir -p /mnt/nvme1n${DEV_ID}p1
        wipefs --all --force /dev/nvme1n${DEV_ID}p1
    done
}

docker_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing docker engine$(tput sgr 0)"
    for DEV_ID in $(seq 1 ${NUM_DEV}); do
        mkfs.xfs /dev/nvme1n${DEV_ID}p1
        mount /dev/nvme1n${DEV_ID}p1 /mnt/nvme1n${DEV_ID}p1
    done
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		DIR=/mnt/nvme1n${DEV_ID}p1/mysql${CONT_ID}
		mkdir -p $DIR
	done
    mkdir -p $DOCKER_ROOT
    systemctl start docker
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
		docker run --name=mysql${CONT_ID} -v /mnt/nvme1n${DEV_ID}p1/mysql${CONT_ID}:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -p $HOST_PORT:3306 -d mysql/mysql-server:8.0
	done
	sleep 20
	docker_healthy
	sleep 30
	
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3305+${CONT_ID}))
		docker exec mysql${CONT_ID} mysql -uroot -p'root' -e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest${CONT_ID};"
	done
}

mkdir -p ${RESULT_DIR}
for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
	for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		rm -rf $INTERNAL_DIR
		mkdir -p $INTERNAL_DIR
		
		#### Docker initialization
		docker_remove
		nvme_flush
		nvme_format
		docker_init
		docker_mysql_gen	

		#### MySQL Prepare
		PREPARE_PIDS=()
		for CONT_ID in $(seq 1 ${NUM_THREAD}); do
			HOST_PORT=$((3305+${CONT_ID}))
			/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} prepare & PREPARE_PIDS+=("$!")
		done
		pid_waits PREPARE_PIDS[@]
		sync; echo 3 > /proc/sys/vm/drop_caches

		#### Blktrace initialization
#		BLKTRACE_PIDS=()
#		for DEV_ID in $(seq 1 ${NUM_DEV}); do
#			blktrace -d /dev/nvme1n${DEV_ID} -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
#		done
#		sleep 5

		#### Inotifywait initilization
		INOTIFY_PIDS=()
		for DEV_ID in $(seq 1 $NUM_DEV); do
			inotifywait -m -r --format 'Time:%T PATH:%w%f EVENTS:%,e' --timefm '%F %T' /mnt/nvme1n${DEV_ID}p1 &> ${INTERNAL_DIR}/inotify-nvme1n${DEV_ID}p1.log & INOTIFY_PIDS+=("$!")
		done
				
		#### MySQL Run
		SYSBENCH_PIDS=()
		for CONT_ID in $(seq 1 ${NUM_THREAD}); do
			HOST_PORT=$((3305+${CONT_ID}))
			/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} run &> ${INTERNAL_DIR}/sysbench${CONT_ID}.output & SYSBENCH_PIDS+=("$!")		
		done
		pid_waits SYSBENCH_PIDS[@]
		pid_kills INOTIFY_PIDS[@]
#		pid_kills BLKTRACE_PIDS[@]
		sleep 5
			
		#### MySQL Cleanup
		CLEAN_PIDS=()
		for CONT_ID in $(seq 1 ${NUM_THREAD}); do
			HOST_PORT=$((3305+${CONT_ID}))
			/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} cleanup & CLEAN_PIDS+=("$!")
		done
		pid_waits CLEAN_PIDS[@]	
		sleep 5
	done
done
