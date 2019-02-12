#!/bin/bash
TARGET_DEV="nvme1n1"
DEVICE="/dev/"$TARGET_DEV
MOUNT="/mnt/"$TARGET_DEV
IODEPTH=1
BS=4k
MIN_NUM_CONT=1  # 2^0 = 1
MAX_NUM_CONT=1  # 2^10 = 1024
RUNTIME=5
RAMPTIME=1
LOG_MSEC=10
SRC_VOLUME=resource
SRC_PATH="/mnt/"$SRC_VOLUME
IMAGE=fio
LOG_PATH=$SRC_PATH/xfs-volume/fio-CONTs-NS1

func_docker()
{
    for pid in ${pids[*]};do
        wait $pid
    done
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
}

func_same_simple()
{
    ARR_JOB=(read)
    for JOB_TYPE in "${ARR_JOB[@]}"
    do
        if [ "$1" = "diff" ]
        then
            MAX_NUM_CONT=8
        fi

        for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT)
        do
            NUM_CONT=$((2**$numcont))

            pids=()
            for CONT_ID in $(seq 1 $NUM_CONT)
            do
                docker run --name cont$CONT_ID -itd \
                --mount type=bind,src=/etc/localtime,dst=/etc/localtime \
                --mount source=$TARGET_DEV,target=$MOUNT \
                --mount source=$SRC_VOLUME,target=$SRC_PATH \
                $IMAGE bin/bash

            done

            for CONT_ID in $(seq 1 $NUM_CONT)
            do
                if [ "$1" = "same" ]
                then
                    FILE_NAME=text1
                else
                    FILE_NAME=text${CONT_ID}
                fi

                FIO_LOG_FILE=/mnt/resource/time-sync/CONC${CONT_ID}.summary
                docker exec cont$CONT_ID \
                    fio --name test --direct=1 --ioengine=libaio --iodepth=$IODEPTH \
                    --filename=$MOUNT/$FILE_NAME --rw=$JOB_TYPE --bs=$BS \
                    --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME --output=$FIO_LOG_FILE &
                pids[${CONT_ID}]=$!
            done
            func_docker
        done
    done
}

if [[ $(docker ps -aq) ]]
then
    docker rm $(docker ps -aq)
fi

func_same_simple "same"
