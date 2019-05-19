#!/bin/bash

#### Parameters
NUM_DEV=4
RESULT_DIR=/mnt/data/motiv/cont-fio/NS${NUM_DEV}
#ARR_NUM_THREAD=(4 16 64 256)
#ARR_COMB_TYPE=("SRxSW" "SRxRW" "RRxSW" "RRxRW")
#ARR_READ_RATIO=(25 50 75) # percentage
#ARR_DEV_SEL=("SS" "RR") # 1: same type -> same dev 2: RR

ARR_NUM_THREAD=(64 256)
ARR_COMB_TYPE=("SRxSW")
ARR_READ_RATIO=(25 50 75) # percentage
ARR_DEV_SEL=("SS" "RR") # 1: same type -> same dev 2: RR

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

fio_waits() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Waiting scheduled fio job in containers$(tput sgr 0)"
	WAIT_FLAG=1
	while [ $WAIT_FLAG -eq 1 ]; do
		if [[ -z "$(at -l)" ]]; then
			WAIT_FLAG=0
		fi
		sleep 1
	done
	sleep 2	
}

fio_waits_cont() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Waiting scheduled fio job in containers$(tput sgr 0)"
	ARRAY=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		ARRAY+=(${CONT_ID})
	done
	
	while [ ${#ARRAY[@]} != 0 ]; do
		for CONT_ID in ${ARRAY[@]}; do
			if [[ -z $(docker exec ID${CONT_ID} bash -c "at -l") ]]; then
				idx=$((${CONT_ID}-1))
				unset ARRAY[$idx]
			fi
		done
	done
	sleep 2	
}

docker_fio_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Generate fio containers$(tput sgr 0)"
	cd dockerfile && docker build . -t fio-centos > /dev/null && cd -

	let NUM_READ="$NUM_THREAD * $READ_RATIO / 100"
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		if [[ $DEV_SEL -eq "SS" ]]; then
			let DEV_ID="($CONT_ID - 1) / $NUM_READ + 1"
		elif [[ $DEV_SEL -eq "RR" ]]; then
			let DEV_ID="(($CONT_ID - 1) % $NUM_DEV) + 1"
		fi

		docker run --network none -itd --privileged \
			--name ID${CONT_ID} \
			-v /etc/localtime:/etc/localtime \
			-v ${RESULT_DIR}:${RESULT_DIR} \
			-v /mnt/nvme1n${DEV_ID}p1:/mnt/nvme1n${DEV_ID}p1 \
			fio-centos /bin/bash
		sleep 2
		docker exec ID${CONT_ID} bash -c "/usr/sbin/atd"	
	done
}

file_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)generate files$(tput sgr 0)"
	NUM_THREAD=$1
	FIO_PIDS=()

	let NUM_READ="$NUM_THREAD * $READ_RATIO / 100"
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		if [[ $DEV_SEL -eq "SS" ]]; then
			let DEV_ID="($CONT_ID - 1) / $NUM_READ + 1"
		elif [[ $DEV_SEL -eq "RR" ]]; then
			let DEV_ID="(($CONT_ID - 1) % $NUM_DEV) + 1"
		fi
		fio --name=ID${CONT_ID} --directory=/mnt/nvme1n${DEV_ID}p1 --filename_format=file${CONT_ID} --nrfiles=1 --size=500m &>/dev/null & FIO_PIDS+=("$!")
	done
	pid_waits FIO_PIDS[@]
}

mkdir -p ${RESULT_DIR}
for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
	for COMB_TYPE in "${ARR_COMB_TYPE[@]}"; do
		for READ_RATIO in "${ARR_READ_RATIO[@]}"; do
			for DEV_SEL in "${ARR_DEV_SEL[@]}"; do
				INTERNAL_DIR=${RESULT_DIR}/${COMB_TYPE}-${READ_RATIO}-${DEV_SEL}-${NUM_THREAD}
				TIME_DIR=${INTERNAL_DIR}/timelog
				rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR $TIME_DIR 
				
				#### Docker initialization
				docker_remove
				nvme_flush
				nvme_format
				docker_init
				docker_fio_gen

				#### Fio initilization
				if [[ $COMB_TYPE -eq "SRxSW" ]]; then
					READ_TYPE=read && WRITE_TYPE=write
				elif [[ $COMB_TYPE -eq "SRxRW" ]]; then
					READ_TYPE=read && WRITE_TYPE=randwrite
				elif [[ $COMB_TYPE -eq "RRxSW" ]]; then 
					READ_TYPE=randread && WRITE_TYPE=write
				elif [[ $COMB_TYPE -eq "RRxRW" ]]; then 
					READ_TYPE=randread && WRITE_TYPE=randwrite
				fi
	
				### Scheduling
				file_gen "$NUM_THREAD"
				DATE_FIO=$(date --date="180 seconds" +"%Y%m%d%H%M.%S") && echo $DATE_FIO

				#### Run fio
				let NUM_READ="$NUM_THREAD * $READ_RATIO / 100"
				echo "$(tput setaf 4 bold)$(tput setab 7)Schedule docker containers$(tput sgr 0)"
				for CONT_ID in $(seq 1 ${NUM_THREAD}); do
					if [[ $DEV_SEL -eq "SS" ]]; then
						let DEV_ID="($CONT_ID - 1) / $NUM_READ + 1"
					elif [[ $DEV_SEL -eq "RR" ]]; then
						let DEV_ID="(($CONT_ID - 1) % $NUM_DEV) + 1"
					fi

					if [[ $CONT_ID -le $NUM_READ ]]; then
						IO_TYPE=$READ_TYPE
					else
						IO_TYPE=$WRITE_TYPE
					fi

					docker exec -d ID${CONT_ID} bash -c "echo "\""fio --name ${IO_TYPE}-TOT${NUM_THREAD}-ID${CONT_ID} --thread=1 --ioengine=libaio --iodepth=8 --bs=8K --rw=${IO_TYPE} --direct=1 --size=500m --time_based --runtime=180 --filename=/mnt/nvme1n${DEV_ID}p1/file${CONT_ID} --log_avg_msec=100 --write_lat_log=${TIME_DIR}/ID${CONT_ID} --write_bw_log=${TIME_DIR}/ID${CONT_ID} --output=${INTERNAL_DIR}/ID${CONT_ID}.summary"\"" | at -t $DATE_FIO"
				done

#				startTime=$(date +"%Y%m%d%H%M.%S")
#				endTime=$DATE_FIO
#				timeToWait=$(echo "$endTime - $startTime"|bc)
#				sleep $timeToWait	
#
#				### Blktrace initialization
#				BLKTRACE_PIDS=()
#				for DEV_ID in $(seq 1 ${NUM_DEV}); do
#					blktrace -d /dev/nvme1n${DEV_ID} -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
#				done

				fio_waits_cont "$num_thread"
#				pid_kills BLKTRACE_PIDS[@]
				echo 3 > /proc/sys/vm/drop_caches
			done
		done
	done
done
