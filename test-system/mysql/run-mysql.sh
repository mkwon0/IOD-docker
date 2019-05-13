#!/bin/bash

NUM_MYSQL=$1
ARR_NUM_MYSQL=($(seq 1 $NUM_MYSQL))
RESULT_DIR="/data/mkwon-mysql/basic-test/"

docker_init() {
	docker stop $(docker ps -aq)
	docker rm $(docker ps -aq)
}

docker_volume_gen() {
	NUM_VOL=4
	for i in $(seq 1 $NUM_VOL);
	do
		docker volume create -d local-persist -o mountpoint=/mnt/nvme0$i --name=volume$i
	done
}

docker_mysql_db_gen() {
	cont=$1
	DB=$2
	docker exec mysql$cont mysql -uroot -p'root' -e "drop database $DB;"
	docker exec mysql$cont mysql -uroot -p'root' -e "CREATE DATABASE $DB;"
}

docker_sysbench_prepare() {
	DB=$1
	HOST_PORT=$2
	OUT_DIR=$3
	MYSQL_ID=$4
	sysbench oltp_read_write --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-db=$DB --mysql-password=root --mysql-host=0.0.0.0 --mysql-port=$HOST_PORT prepare &
	PID=$! 
	docker exec mysql${MYSQL_ID} bash -c 'ps -axf | grep mysqld' > ${OUT_DIR}/mysql${MYSQL_ID}.ppids
	return "$PID"
}

docker_sysbench_run() {
	DB=$1
	HOST_PORT=$2
	OUT_DIR=$3
	sysbench oltp_read_only --table-size=10000000 --db-driver=mysql --mysql-user=root --mysql-db=$DB --mysql-password=root \
							--mysql-host=0.0.0.0 --mysql-port=${HOST_PORT} --time=30 run > $OUT_DIR/outputs1.log &
	PID=$!
	docker exec mysql1 bash -c 'ps -axf | grep mysqld' > ${OUT_DIR}/mysql1.ppids
	return "$PID"
}

pid_waits () {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		wait $pid
	done 
}

pid_kills () {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		kill -15 $pid
	done 
}

test_all_run () {
	SYSBENCH_PIDS=()
	NUM_CONT=$1
	for i in $(seq 1 $NUM_CONT); do
		HOST_PORT=$((3305+$j))
		docker_sysbench_run sbtest $HOST_PORT ${RESULT_DIR}${NUM_CONT}/outputs${i}.log & SYSBENCH_PIDS+=("$!") 
	done
	pid_waits SYSBENCH_PIDS[@]
}

test_other_prepare () {
	SYSBENCH_PIDS=()
	NUM_CONT=$1
	docker_sysbench_run sbtest 3306 ${RESULT_DIR}${NUM_CONT}
	SYSBENCH_PIDS+=("$?")	
	for i in $(seq 2 $NUM_CONT); do
		HOST_PORT=$((3305+$i))
		docker_sysbench_prepare test $HOST_PORT ${RESULT_DIR}${NUM_CONT} $i
		SYSBENCH_PIDS+=("$?") 	
	done
#	pid_waits SYSBENCH_PIDS[@]
}

for i in "${ARR_NUM_MYSQL[@]}"; do
	mkdir -p ${RESULT_DIR}$i
	for j in $(seq 2 $i); do
		docker_mysql_db_gen $j test
	done
	## Blktrace initialization
	BLKTRACE_PIDS=()
	for j in $(seq 1 $i); do
		blktrace -d /dev/nvme0n$j -w 600 -D ${RESULT_DIR}$i & BLKTRACE_PIDS+=("$!")
	done
	sleep 4

	## Sysbench
	#test_all_run $i
	test_other_prepare $i
	sleep 40
	pid_kills BLKTRACE_PIDS[@]

	## Keep PIDs into file
	printf "%s\n" "${BLKTRACE_PIDS[@]}" > ${RESULT_DIR}$i/blktrace.pids
	printf "%s\n" "${SYSBENCH_PIDS[@]}" > ${RESULT_DIR}$i/sysbench.pids
done
