#!/bin/bash

RESULT_DIR=/mnt/data/motiv/NS4/all
#ARR_NUM_THREAD=(4 16 64 256 1024)
ARR_NUM_THREAD=(1024)
#ARR_IO_TYPE=(read randread)
ARR_IO_TYPE=(randread)

pid_kills() {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		kill -15 $pid
	done
}

nvme_flush() {
	for dev_id in $(seq 1 4); do
		nvme flush /dev/nvme2n${dev_id}
	done
}

gen_jobfile () {
	NUM_THREAD=$1
	IO_TYPE=$2
	rm -rf multiple.fio
	cp base.fio multiple.fio

	for thread_id in $(seq 1 ${NUM_THREAD}); do
		dev_id=$(($((${thread_id}-1))%4+1))
		cat <<EOT >> multiple.fio 
[job${thread_id}]
rw=${IO_TYPE}
filename=/dev/nvme2n${dev_id}p1
name=thread${thread_id}-nvme2n${dev_id}p1
EOT
	done	
}


mkdir -p ${RESULT_DIR}
for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		mkdir -p $INTERNAL_DIR 
		nvme_flush
		#### FIO jobfile generation
		gen_jobfile $NUM_THREAD $IO_TYPE
		BLKTRACE_PIDS=()
		for i in $(seq 1 4); do
			blktrace -d /dev/nvme2n$i -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
		done
		fio --output=${INTERNAL_DIR}/fio.summary multiple.fio
		pid_kills BLKTRACE_PIDS[@]
		sleep 5
	done
done
