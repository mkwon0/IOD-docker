#!/bin/bash

#### Parameters
NUM_DEV=4
TEST_TYPE=mysql

MAX_MEM=520
ARR_SWAP_TYPE=(multiple)
ARR_IO_TYPE=(oltp_read_only oltp_write_only)
ARR_NUM_THREAD=(64 128)
ARR_MEM_RATIO=(10 20 30)

#### MySQL Parameters
OPTIONS="--threads=1 --events=10000 --time=0 \
         --table-size=1000000 --db-driver=mysql \
         --mysql-host=0.0.0.0 \
         --mysql-user=root --mysql-password=root \
         --mysql-ignore-errors="all" \
         --histogram "

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme0n1/docker

#### ftrace
FTRACE_ARR=(add_to_swap try_to_unmap swap_writepage delete_from_swap_cache lookup_swap_cache swapin_readahead read_swap_cache_async mark_page_accessed swap_free page_add_anon_rmap do_swap_page)

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
			/home/mkwon/src/util-linux-swap/swapoff /mnt/nvme0n${DEV_ID}/swapfile${CONT_ID}
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
		DATA_DIR=/mnt/nvme0n${DEV_ID}/mysql-data${CONT_ID}
		LOG_DIR=/mnt/nvme0n${DEV_ID}/mysql-log${CONT_ID}
		CONF_DIR=/mnt/nvme0n${DEV_ID}/mysql-conf${CONT_ID}
		mkdir -p $DATA_DIR $LOG_DIR $CONF_DIR
	done
    mkdir -p $DOCKER_ROOT

	iptables -t nat -N DOCKER
	iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
	iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL ! --dst 172.17.0.1/8 -j DOCKER
	service iptables save
	service iptables restart
    systemctl restart docker
}

swapfile_public_single_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing public swapfile$(tput sgr 0)"

	SWAPFILE=/mnt/nvme0n1/swapfile1
	let SWAPSIZE="512 * $NUM_THREAD"
	dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAPSIZE
	chmod 600 $SWAPFILE
	mkswap -L swapfile1 $SWAPFILE

	echo "/mnt/nvme0n1/swapfile1 swap swap defaults,pri=60 0 0" >> /etc/fstab

	/home/mkwon/src/util-linux-swap/swapon -a
	cat /proc/swaps

	awk '$1 !~/swapfile/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

swapfile_public_multiple_init() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Initializing public swapfile$(tput sgr 0)"

	let SWAPSIZE="512 * $NUM_THREAD / 4"
	for DEV_ID in $(seq 1 $NUM_DEV); do
		SWAPFILE=/mnt/nvme0n${DEV_ID}/swapfile${DEV_ID}
		dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAPSIZE
		chmod 600 $SWAPFILE
		mkswap -L swapfile${DEV_ID} $SWAPFILE
	done

	echo "/mnt/nvme0n1/swapfile1 swap swap defaults,pri=60 0 0" >> /etc/fstab
	echo "/mnt/nvme0n2/swapfile2 swap swap defaults,pri=60 0 0" >> /etc/fstab
	echo "/mnt/nvme0n3/swapfile3 swap swap defaults,pri=60 0 0" >> /etc/fstab
	echo "/mnt/nvme0n4/swapfile4 swap swap defaults,pri=60 0 0" >> /etc/fstab

	/home/mkwon/src/util-linux-swap/swapon -a
	cat /proc/swaps

	awk '$1 !~/swapfile/ {print }' /etc/fstab > /etc/fstab.bak
	rm -rf /etc/fstab && mv /etc/fstab.bak /etc/fstab
}

docker_healthy() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Check docker healthy$(tput sgr 0)"
	while docker ps -a | grep -c 'starting\|unhealthy' > /dev/null;
	do
		sleep 1;
	done
}

docker_mysql_gen() {
    echo "$(tput setaf 4 bold)$(tput setab 7)Generating mysql containers$(tput sgr 0)"
	systemctl restart mysqld

	if [ $MEM_RATIO -eq 0 ]; then
		MEMSIZE="4m"
	else
		let MEMSIZE="$MAX_MEM * $MEM_RATIO / 100"
		MEMSIZE=$( printf "%dm" $MEMSIZE )
	fi

	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3306+${CONT_ID}))
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		docker run --name=mysql-data${CONT_ID} \
			--oom-kill-disable=true \
			--memory $MEMSIZE --memory-swap -1 \
			--memory-swappiness "100" \
			-v /mnt/nvme0n${DEV_ID}/mysql-data${CONT_ID}:/var/lib/mysql \
			-v /mnt/nvme0n${DEV_ID}/mysql-log${CONT_ID}:/var/log/mysql \
			-v /mnt/nvme0n${DEV_ID}/mysql-conf${CONT_ID}:/etc/mysql/conf.d \
			-e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% \
			-p $HOST_PORT:3306 -d mysql/mysql-server:8.0
#		DID=$(docker inspect mysql-data${CONT_ID} --format {{.Id}})
#		cat /sys/fs/cgroup/memory/docker/$DID/memory.swapfile
	done
	sleep 20
	docker_healthy
	sleep 30
	
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3306+${CONT_ID}))
		docker exec mysql-data${CONT_ID} mysql -uroot -p'root' \
		-e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest${CONT_ID};"
	done
}

docker_mysql_prepare() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Prepare Sysbench$(tput sgr 0)"
	PREPARE_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3306+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} prepare & PREPARE_PIDS+=("$!")
	done
	pid_waits PREPARE_PIDS[@]
}

docker_mysql_run() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Execute Sysbench$(tput sgr 0)"
	SYSBENCH_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3306+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} run &> ${INTERNAL_DIR}/sysbench${CONT_ID}.output & SYSBENCH_PIDS+=("$!")		
	done
	pid_waits SYSBENCH_PIDS[@]
	sleep 5
}

docker_mysql_cleanup() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Cleanup Sysbench$(tput sgr 0)"
	CLEAN_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((3306+${CONT_ID}))
		/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest${CONT_ID} cleanup & CLEAN_PIDS+=("$!")
	done
	pid_waits CLEAN_PIDS[@]	
	sleep 5
}

ftrace_start() {
	cd /sys/kernel/debug/tracing
	echo nop > current_tracer
	echo "${FTRACE_ARR[*]}" > set_ftrace_filter 
	echo 1 > function_profile_enabled
}

ftrace_end() {
	cd /sys/kernel/debug/tracing
	cat trace_stat/function* > ${INTERNAL_DIR}/trace.output
	echo 0 > function_profile_enabled
}

anal_start() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Enable analysis$(tput sgr 0)"
	INOTIFY_PIDS=()
	for DEV_ID in $(seq 1 $NUM_DEV); do
		inotifywait -m -r --format 'Time:%T PATH:%w%f EVENTS:%,e' --timefm '%F %T' /mnt/nvme0n${DEV_ID} &> ${INTERNAL_DIR}/inotify-nvme0n${DEV_ID}.log & INOTIFY_PIDS+=("$!")
	done
	
	BLKTRACE_PIDS=()
	for DEV_ID in $(seq 1 ${NUM_DEV}); do
		blktrace -d /dev/nvme0n${DEV_ID} -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
	done
	ftrace_start	
}

anal_end() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Disable analysis$(tput sgr 0)"
	ftrace_end
	pid_kills BLKTRACE_PIDS[@]
	pid_kills INOTIFY_PIDS[@]
}

for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		for MEM_RATIO in "${ARR_MEM_RATIO[@]}"; do
			for SWAP_TYPE in "${ARR_SWAP_TYPE[@]}"; do
				RESULT_DIR=/mnt/data/motiv/cont-${TEST_TYPE}/${SWAP_TYPE}
				mkdir -p ${RESULT_DIR}
				INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}-ratio${MEM_RATIO}
				rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR
				
				#### Docker initialization
				docker_remove
				nvme_flush
				nvme_format
				docker_init
				if [ $SWAP_TYPE == "single" ]; then
					swapfile_public_single_init
				else
					swapfile_public_multiple_init
				fi

				sleep 10
				docker_mysql_gen
				sleep 10
				docker_mysql_prepare

#				anal_start
				docker_mysql_run
#				anal_end

				docker_mysql_cleanup
			done
		done
	done
done
