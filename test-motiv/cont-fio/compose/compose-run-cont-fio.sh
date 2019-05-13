#!/bin/bash

#### Parameters
NUM_DEV=$1
#NUM_DEV=4
RESULT_DIR=/mnt/data/motiv/cont-fio/NS${NUM_DEV}
#ARR_NUM_THREAD=(4 16 64 256)
ARR_NUM_THREAD=(512)
#ARR_IO_TYPE=(read randread write randwrite)
ARR_IO_TYPE=(read)

for i in $(seq 1 ${NUM_DEV}); do
	DEV_ID=$((${NUM_DEV}-$i+1))
	ARR_DEV_ID+=(${DEV_ID})
done

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme1n1p1/docker

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

delPart() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Delete existing nvme partition$(tput sgr 0)"
	for DEV_ID in $(seq 1 4); do
		echo -e "d\nw" | fdisk /dev/nvme1n${DEV_ID}
	done
}

genPart() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Regenerate nvme partition$(tput sgr 0)"
	SIZE=$((400/${NUM_DEV}))
	for DEV_ID in $(seq 1 ${NUM_DEV}); do
		echo -e "o\nn\np\n1\n\n+${SIZE}G\nw" | fdisk /dev/nvme1n${DEV_ID}
	done
	sleep 3 
}

nvme_format() {
	delPart
	echo "$(tput setaf 4 bold)$(tput setab 7)Format nvme block devices$(tput sgr 0)"
	for DEV_ID in $(seq 1 4); do
		nvme format /dev/nvme1n${DEV_ID} -n ${DEV_ID} --ses=0
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
	echo "$(tput setaf 4 bold)$(tput setab 7)Flush nvme block devices$(tput sgr 0)"
	for DEV_ID in $(seq 1 ${NUM_DEV}); do
		nvme flush /dev/nvme1n${DEV_ID}
	done
}

docker_remove() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Start removing exisintg docker$(tput sgr 0)"
	docker ps -aq | xargs --no-run-if-empty docker stop
	docker ps -aq | xargs --no-run-if-empty docker rm
	systemctl stop docker 
	
	for DEV_ID in $(seq 1 ${NUM_DEV}); do
		if mountpoint -q /mnt/nvme1n${DEV_ID}p1; then
			umount /mnt/nvme1n${DEV_ID}p1
		fi
		rm -rf /mnt/nvme1n${DEV_ID}p1
		mkdir -p /mnt/nvme1n${DEV_ID}p1
		wipefs --all --force /dev/nvme1n${DEV_ID}p1
	done
}

docker_init() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Initializing docker engine$(tput sgr 0)"
	for DEV_ID in $(seq 1 ${NUM_DEV}); do
		mkfs.xfs /dev/nvme1n${DEV_ID}p1
		mount /dev/nvme1n${DEV_ID}p1 /mnt/nvme1n${DEV_ID}p1
	done
	mkdir -p $DOCKER_ROOT
	systemctl start docker
}

file_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)generate files$(tput sgr 0)"
	NUM_THREAD=$1
	FIO_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		fio --name=ID${CONT_ID} --directory=/mnt/nvme1n${DEV_ID}p1 --filename_format=file${CONT_ID} --nrfiles=1 --size=500m &>/dev/null & FIO_PIDS+=("$!")
	done
	pid_waits FIO_PIDS[@]
}

__compose_header() {
cat <<EOT >> docker-compose.yml
version: '3'
services:
EOT
}
__compose_gen() {
cat <<EOT >> docker-compose.yml
  id${CONT_ID}:
    build: .
    volumes:
      - "/mnt/nvme1n${DEV_ID}p1:/mnt/nvme1n${DEV_ID}p1"
      - "${RESULT_DIR}:${RESULT_DIR}"
    command: >
      bash -c "fio --name ${IO_TYPE}-TOT${NUM_THREAD}-ID${CONT_ID} --thread=1 --ioengine=libaio --iodepth=8 --bs=8K --rw=${IO_TYPE} --direct=1 --size=500m --time_based --runtime=15 --filename=/mnt/nvme1n${DEV_ID}p1/file${CONT_ID} --output=${INTERNAL_DIR}/ID${CONT_ID}.summary"
EOT
}

docker_compose_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Generate docker-compose file$(tput sgr 0)"
	rm -f docker-compose.yml
	__compose_header

for CONT_ID in $(seq 1 ${NUM_THREAD}); do
	DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
	__compose_gen
done
}

docker_compose_wait() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Waiting fio jobs in containers$(tput sgr 0)"
	WAIT_FLAG=1
	while [ $WAIT_FLAG -eq 1 ]; do
		if [[ -z "$(docker-compose ps | grep Up)" ]]; then
			WAIT_FLAG=0
		fi
		sleep 1
	done
	sleep 2	
}

mkdir -p ${RESULT_DIR}
for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
	for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
		INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD}
		rm -rf $INTERNAL_DIR 
		mkdir -p $INTERNAL_DIR
		
		#### Docker initialization
#		docker_remove
#		nvme_flush
#		nvme_format
#		docker_init
	
		### Scheduling
#		file_gen "$NUM_THREAD"
#		docker_compose_gen
		docker-compose build --parallel
		
		### Blktrace initialization
#		BLKTRACE_PIDS=()
#		for DEV_ID in $(seq 1 ${NUM_DEV}); do
#			blktrace -d /dev/nvme1n${DEV_ID} -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
#		done

		#### Run fio
		docker-compose up --no-start
		docker_compose_wait

#		pid_kills BLKTRACE_PIDS[@]
		docker-compose rm -f
		echo 3 > /proc/sys/vm/drop_caches
	done
done
