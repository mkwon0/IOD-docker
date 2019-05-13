#!/bin/bash

NUM_DEV=4
RESULT_DIR=/mnt/data/motiv/proc/NS${NUM_DEV}/all
ARR_NUM_THREAD=(4 16 64 256 1024)
ARR_IO_TYPE=(read randread write randwrite)
for i in $(seq 1 ${NUM_DEV}); do
	DEV_ID=$((${NUM_DEV}-$i+1))
	ARR_DEV_ID+=(${DEV_ID})
done

pid_kills() {
	PIDS=("${!1}")
	for pid in "${PIDS[*]}"; do
		kill -15 $pid
	done
}

delPart() {
#for dev_id in $(seq 1 ${num_dev}); do
for dev_id in $(seq 1 4); do
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/nvme1n${dev_id}
	d
	w
	q
EOF
done
}

genPart() {
SIZE=$((400/${NUM_DEV}))
for dev_id in $(seq 1 ${NUM_DEV}); do
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/nvme1n${dev_id} 
	o
	n
	p
	1
	
	+${SIZE}G
	w
	q
EOF
done
sleep 3 
}

nvme_format() {
	delPart
#	for dev_id in "${ARR_DEV_ID[@]}"; do
	for dev_id in $(seq 1 4); do
		nvme format /dev/nvme1n${dev_id} -n ${dev_id} --ses=0
	done
	sleep 1

	FLAG=true
	while $FLAG; do
		NUSE="$(nvme id-ns /dev/nvme1n1 -n 1 | grep nuse | awk '{print $3}')"
		if [[ $NUSE -eq "0" ]]; then
			FLAG=false
			echo "nvme format done"
		fi
	done
	sleep 1
	genPart
}

nvme_flush() {
	for dev_id in $(seq 1 ${NUM_DEV}); do
		nvme flush /dev/nvme1n${dev_id}
	done
}

gen_jobfile () {
	NUM_THREAD=$1
	IO_TYPE=$2
	rm -rf multiple.fio
	cp base.fio multiple.fio

	for thread_id in $(seq 1 ${NUM_THREAD}); do
		dev_id=$(($((${thread_id}-1))%${NUM_DEV}+1))
		cat <<EOT >> multiple.fio 
[job${thread_id}]
rw=${IO_TYPE}
filename=/dev/nvme1n${dev_id}p1
name=thread${thread_id}-nvme1n${dev_id}p1
EOT
	done	
}


mkdir -p ${RESULT_DIR}
for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
	for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		mkdir -p $INTERNAL_DIR
		nvme_flush

		#### Initialization for read
		if [[ $IO_TYPE == "read" ]] && [[ $NUM_THREAD == "4" ]]; then
			delPart
			genPart
			fio fill${NUM_DEV}.fio
		fi

		#### Initialization for write
		if [[ $IO_TYPE == *"write"* ]]; then
			nvme_format
		fi
		#### FIO jobfile generation
		gen_jobfile $NUM_THREAD $IO_TYPE
		BLKTRACE_PIDS=()
		for i in $(seq 1 ${NUM_DEV}); do
			blktrace -d /dev/nvme1n$i -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
		done
		fio --output=${INTERNAL_DIR}/fio.summary multiple.fio
		pid_kills BLKTRACE_PIDS[@]
		sleep 10
	done
done
