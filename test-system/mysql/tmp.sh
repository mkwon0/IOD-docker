#!/bin/bash

for i in $(seq 1 9); do
	NUM_CONT=$((2**i))
	./test-mysql.sh ${NUM_CONT} oltp_read_only
	./test-mysql.sh ${NUM_CONT} oltp_write_only
done

#./test-mysql.sh 2 oltp_read_only
#./test-mysql.sh 3 oltp_read_only
#./test-mysql.sh 4 oltp_read_only
#./test-mysql.sh 2 oltp_write_only
#./test-mysql.sh 3 oltp_write_only
#./test-mysql.sh 4 oltp_write_only
#./test-checkpoint.sh 2 oltp_read_only
#./test-checkpoint.sh 3 oltp_read_only
#./test-checkpoint.sh 4 oltp_read_only
#./test-checkpoint.sh 2 oltp_write_only
#./test-checkpoint.sh 3 oltp_write_only
#./test-checkpoint.sh 4 oltp_write_only

#./test-mysql.sh 2 oltp_update_index 
#./test-mysql.sh 3 oltp_update_index
#
#./test-mysql.sh 2 oltp_insert
#./test-mysql.sh 3 oltp_insert 
#
#./test-mysql.sh 2 oltp_update_non_index
#./test-mysql.sh 3 oltp_update_non_index
