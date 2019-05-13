#!/bin/bash

ANAL_PATH=/data/mkwon-mysql/test-interf/oltp_write_only
for i in $(seq 2 4); do
	for j in $(seq 1 $i); do
		cd ${ANAL_PATH}/total-cont$i && blkparse -i nvme0n$j -f "%5T.%9t, %p, %C, %a, %d, %N\n" -o blktrace-nvme0n$j.log && cd -
	done
done
