#!/bin/bash

#### Parameters
NUM_DEV=4
TEST_TYPE=mysql

ARR_SWAP_TYPE=(private)
ARR_IO_TYPE=(oltp_write_only)
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
DOCKER_ROOT=/mnt/nvme0n1/docker

checker () {
	PID=$(docker inspect --format '{{.State.Pid}}' mysql1)
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
	DIR=/mnt/nvme0n1/mysql1
	rm -rf $DIR && mkdir -p $DIR
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
	echo "gen" >> stats
	docker run --name=mysql1 \
		-v /mnt/nvme0n1/mysql1:/var/lib/mysql \
		-e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% \
		-p 3307:3306 -d mysql/mysql-server:8.0 &
#			--memory "450m" --memory-swap "450m" \
#			--memory-swapfile "/root/swapfile01" \
	GEN_PID=$!
	wait $GEN_PID

	echo "healthy" >> stats
	docker_healthy
	
	echo "create table" >> stats
	docker exec mysql1 mysql -uroot -p'root' \
		-e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest1;"
}

docker_mysql_prepare() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Prepare Sysbench$(tput sgr 0)"
	echo "prepare" >> stats
	/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=3307 --mysql-db=sbtest1 prepare &
	PREPARE_PID=$!
	wait $PREPARE_PID
}

docker_mysql_run() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Execute Sysbench$(tput sgr 0)"
	echo "run" >> stats
	/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=3307 --mysql-db=sbtest1 run &> ${INTERNAL_DIR}/sysbench1.output &
	SYSBENCH_PID=$!
	wait $SYSBENCH_PID
}

docker_mysql_cleanup() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Cleanup Sysbench$(tput sgr 0)"
	echo "cleanup" >> stats
	/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=3307 --mysql-db=sbtest1 cleanup &
	CLEAN_PID=$!
	wait $CLEAN_PID
}

for SWAP_TYPE in "${ARR_SWAP_TYPE[@]}"; do
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		#### Docker initialization
		rm -rf stats
		docker_remove
		docker_init
		
		mem_checker	&
		CHECKER_PID=$!	
		docker_mysql_gen

		docker_mysql_prepare
		docker_mysql_run
		docker_mysql_cleanup
		kill -15 $CHECKER_PID
	done
done
