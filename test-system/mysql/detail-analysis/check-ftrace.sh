#!/bin/bash

ARR_NUM_MYSQL=(2)
RESULT_DIR="results"
MONITORDIR="/mnt/nvme0n1/"

monitor() {
	inotifywait -m -r -e create --format "%f" "$1"
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
	strace sysbench oltp_read_write --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-db=$DB --mysql-password=root --mysql-host=0.0.0.0 --mysql-port=$HOST_PORT prepare 2>$OUT_DIR
}

docker_sysbench_run() {
	DB=$1
	HOST_PORT=$2
	OUT_DIR=$3
	strace sysbench oltp_read_only --table-size=10000000 --db-driver=mysql --mysql-user=root --mysql-db=$DB --mysql-password=root \
							--mysql-host=0.0.0.0 --mysql-port=${HOST_PORT} --max-time=30 run 2>$OUT_DIR
}

pid_waits () {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		wait $pid
	done 
}

test_other_prepare () {
	SYSBENCH_PIDS=()
	NUM_CONT=$1
#	monitor "$MONITORDIR" & MONITOR_PID="$!"
	docker_sysbench_run sbtest 3306 strace-mysql1.log  & SYSBENCH_PIDS+=("$!")	
	for i in $(seq 2 $NUM_CONT); do
		HOST_PORT=$((3305+$i))
		docker_sysbench_prepare test $HOST_PORT strace-mysql${i}.log & SYSBENCH_PIDS+=("$!") 	
	done
	pid_waits SYSBENCH_PIDS[@]
#	kill -15 $MONITOR_PID
}

for i in "${ARR_NUM_MYSQL[@]}"; do
	mkdir -p ${RESULT_DIR}$i
	sync; echo 3 > /proc/sys/vm/drop_caches
	for j in $(seq 2 $i); do
		docker_mysql_db_gen $j test
	done
	test_other_prepare $i
done
