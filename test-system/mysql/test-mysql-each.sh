#!/bin/bash

NUM_CONT=$1
ARR_NUM_MYSQL=($(seq 1 $NUM_CONT))
TEST_TYPE=$2 # oltp_read_only oltp_write_only
OUTPUT=$3
CASE=$4

OPTIONS="--threads=1 --events=10000 \
		 --table-size=1000 --db-driver=mysql \
		 --mysql-db=sbtest --mysql-host=0.0.0.0 \
		 --mysql-user=root --mysql-password=root \
		 --histogram "

if [ $CASE -eq 1 ]; then
	for i in "${ARR_NUM_MYSQL[@]}"; do
		HOST_PORT=$((3305+$i))
		sysbench $TEST_TYPE $OPTIONS --mysql-port=$HOST_PORT prepare 
	done
elif [ $CASE -eq 2 ]; then
	for i in "${ARR_NUM_MYSQL[@]}"; do
		HOST_PORT=$((3305+$i))
		sysbench $TEST_TYPE $OPTIONS --mysql-port=$HOST_PORT run > $OUTPUT 
	done
elif [ $CASE -eq 3 ]; then
	for i in "${ARR_NUM_MYSQL[@]}"; do
		HOST_PORT=$((3305+$i))
		sysbench $TEST_TYPE $OPTIONS --mysql-port=$HOST_PORT cleanup
	done
fi 
