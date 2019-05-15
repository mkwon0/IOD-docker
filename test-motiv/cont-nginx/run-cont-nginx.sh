#!/bin/bash

#### Parameters
NUM_DEV=$1
RESULT_DIR=/mnt/data/motiv/cont-nginx/NS${NUM_DEV} && mkdir -p $RESULT_DIR
ARR_NUM_THREAD=(4 16 64 256)
ARR_IO_TYPE=(AB)

for i in $(seq 1 ${NUM_DEV}); do
	DEV_ID=$((${NUM_DEV}-$i+1))
	ARR_DEV_ID+=(${DEV_ID})
done

#### Docker Parameters
DOCKER_ROOT=/mnt/nvme1n1p1/docker

#### Functions
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
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		DIR=/mnt/nvme1n${DEV_ID}p1/nginx${CONT_ID}
	done
    mkdir -p $DOCKER_ROOT
    systemctl start docker
}

docker_nginx_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)Generate nginx containers$(tput sgr 0)"
#	cd dockerfile && docker build . -t nginx-test > /dev/null && cd -
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		HOST_PORT=$((32769+${CONT_ID}))
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
#		docker run --name=nginx${CONT_ID} -v /mnt/nvme1n${DEV_ID}p1/nginx${CONT_ID}:/data/nginx -p ${HOST_PORT}:80 -d nginx-test 	
		docker run --name=nginx${CONT_ID} -v /mnt/nvme1n${DEV_ID}p1/nginx${CONT_ID}:/data/nginx -p ${HOST_PORT}:80 -d nginx:1.16 	
	done
}

file_gen() {
	echo "$(tput setaf 4 bold)$(tput setab 7)generate files$(tput sgr 0)"
	DD_PIDS=()
	for CONT_ID in $(seq 1 ${NUM_THREAD}); do
		DEV_ID=$(($((${CONT_ID}-1))%${NUM_DEV}+1))
		dd if=/dev/zero of=/mnt/nvme1n${DEV_ID}p1/nginx${CONT_ID}/file${CONT_ID} count=102400 bs=4096 > /dev/null & DD_PIDS+=("$!")
	done
	pid_waits DD_PIDS[@]
}

main () {
	for IO_TYPE in "${ARR_IO_TYPE[@]}"; do
		for NUM_THREAD in "${ARR_NUM_THREAD[@]}"; do
			INTERNAL_DIR=${RESULT_DIR}/${IO_TYPE}-${NUM_THREAD} && rm -rf $INTERNAL_DIR && mkdir -p $INTERNAL_DIR

			#### Docker initialization
			docker_remove
			nvme_flush
			nvme_format
			docker_init
			docker_nginx_gen	

			#### nginx test preparation
			file_gen

			#### Blktrace initialization
			echo "$(tput setaf 4 bold)$(tput setab 7)Initialize blktrace and execute apachebench$(tput sgr 0)"	
			BLKTRACE_PIDS=()
			for DEV_ID in $(seq 1 ${NUM_DEV}); do
				blktrace -d /dev/nvme1n${DEV_ID} -w 600 -D ${INTERNAL_DIR} & BLKTRACE_PIDS+=("$!")
			done
			sleep 5
		
			#### nginx benchmark (ApacheBench) Run
			APACHEBENCH_PIDS=()
			for CONT_ID in $(seq 1 ${NUM_THREAD}); do
				HOST_PORT=$((32769+${CONT_ID}))
				OUTPUT_PERCENT=${INTERNAL_DIR}/ab${CONT_ID}.percent
				OUTPUT_GNUPLOT=${INTERNAL_DIR}/ab${CONT_ID}.gnudata
				OUTPUT_SUMMARY=${INTERNAL_DIR}/ab${CONT_ID}.summary
				
				ab -v 2 -t 180 -n 1000000 -c 1000 -e $OUTPUT_PERCENT -g $OUTPUT_GNUPLOT http://localhost:${HOST_PORT}/file${CONT_ID} > $OUTPUT_SUMMARY 2>&1 & APACHEBENCH_PIDS+=("$!")	
			done
			pid_waits APACHEBENCH_PIDS[@]
			pid_kills BLKTRACE_PIDS[@]
			sleep 5
		done
	done
}

main
