#!/bin/bash

NUM_CONT=$1
TEST_TYPE=$2 # oltp_read_only oltp_write_only

OPTIONS="--threads=1 --events=10000 \
		 --table-size=1000000 --db-driver=mysql \
		 --mysql-db=sbtest --mysql-host=0.0.0.0 \
		 --mysql-user=root --mysql-password=root \
		 --histogram "

sysbench $TEST_TYPE $OPTIONS --mysql-port=3306 prepare
sysbench $TEST_TYPE $OPTIONS --mysql-port=3306 run
sysbench $TEST_TYPE $OPTIONS --mysql-port=3306 cleanup
