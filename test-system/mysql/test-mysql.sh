#!/bin/bash

DOCKER_ROOT_DIR=/mnt/nvme0n1
RESULT_PATH=/data/mkwon-mysql/test-interf
mkdir -p $RESULT_PATH

NUM_CONT=$1
TEST_TYPE=$2  # oltp_read_only oltp_write_only
#TEST_PATH=/usr/local/share/sysbench/${TEST_TYPE}.lua
TEST_PATH=$TEST_TYPE

OPTIONS="--threads=1 --events=10000 --time=0 \
		 --table-size=1000000 --db-driver=mysql \
		 --mysql-host=0.0.0.0 \
		 --mysql-user=root --mysql-password=root \
		 --mysql-ignore-errors="all" \
		 --histogram "

pid_kills () {
    PIDS=("${!1}")
    for pid in "${PIDS[*]}"; do
        kill -15 $pid
    done
}

pid_waits () {
    PIDS=("${!1}")
    for pid in "${PIDS[*]}"; do
        wait $pid
    done
}

ARR_NUM_MYSQL=($(seq $NUM_CONT $NUM_CONT))
for i in "${ARR_NUM_MYSQL[@]}"; do
	RESULT_DIR=${RESULT_PATH}/$TEST_TYPE/total-cont$i
	rm -rf ${RESULT_DIR}
	mkdir -p $RESULT_DIR
	./genMySQL.sh $i
	docker ps -a > $RESULT_DIR/docker-pids.log
	sleep 10
	
	################# PREPARE
	PREPARE_PIDS=()
	for j in $(seq 1 $i); do
		HOST_PORT=$((3305+$j))
		/usr/local/bin/sysbench $TEST_PATH $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest$j prepare & PREPARE_PIDS+=("$!")
	done
	pid_waits PREPARE_PIDS[@]
	sync; echo 3 > /proc/sys/vm/drop_caches

	################# RUN
	## fatrace initialization
	echo "fatrace init"
	FATRACE_PIDS=()
	MAX=$i
	if [ $i -gt 4 ]; then
		MAX=4
	fi
	for j in $(seq 1 $MAX); do
		inotifywait -m -r --format 'Time:%T PATH:%w%f EVENTS:%,e' --timefm '%F %T' /mnt/nvme0n$j &> ${RESULT_DIR}/inotify-nvme0n${j}.log & FATRACE_PIDS+=("$!")
	done
	sleep 5
	## Blktrace initialization
	echo "blktrace init"
	BLKTRACE_PIDS=()
	for j in $(seq 1 $MAX); do
		blktrace -d /dev/nvme0n$j -w 600 -D ${RESULT_DIR} & BLKTRACE_PIDS+=("$!")
	done
	sleep 5

	## run
	echo "run"
	SYSBENCH_PIDS=()
	for j in $(seq 1 $i); do
		HOST_PORT=$((3305+$j))
		/usr/local/bin/sysbench $TEST_PATH $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest$j run &> ${RESULT_DIR}/sysbench${j}.output & SYSBENCH_PIDS+=("$!")
	done

	pid_waits SYSBENCH_PIDS[@]
	pid_kills BLKTRACE_PIDS[@]
	pid_kills FATRACE_PIDS[@]
	sleep 5

	############### Cleanup
	CLEAN_PIDS=()
	for j in $(seq 1 $i); do
		HOST_PORT=$((3305+$j))
		/usr/local/bin/sysbench $TEST_PATH $OPTIONS --mysql-port=$HOST_PORT --mysql-db=sbtest$j cleanup & CLEAN_PIDS+=("$!")
	done
	pid_waits CLEAN_PIDS[@]
	sleep 5
done 
