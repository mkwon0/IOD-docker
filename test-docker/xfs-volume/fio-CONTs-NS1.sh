#!/bin/bash
DEV="nvme1n1"
MOUNT_PATH="/mnt/"$DEV
QD=32
BS=4k
MIN_NUM_CONT=7  # 2^0 = 1
MAX_NUM_CONT=7  # 2^10 = 1024
RUNTIME=15
RAMPTIME=1
LOG_MSEC=10
SRC_VOLUME=resource
SRC_PATH="/mnt/"$SRC_VOLUME
LOG_PATH=$SRC_PATH/time-sync/fio-singleNS-1n1-CONTs
IMAGE=fio

func_docker()
{
    for pid in ${pids[*]}; do
        wait $pid
    done
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
}

func_same_simple()
{
    for JOB_TYPE in "${ARR_JOB[@]}"; do
        for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT); do
            NUM_CONT=$((2**$numcont))
            for CONT_ID in $(seq 1 $NUM_CONT); do
                echo "create CONC$NUM_CONT ID$CONT_ID"
                docker run --name cont$CONT_ID -itd \
                    --mount source=$DEV,target=$MOUNT_PATH \
                    --mount source=$SRC_VOLUME,target=$SRC_PATH \
                    $IMAGE bin/bash
            done

            pids=()
            for CONT_ID in $(seq 1 $NUM_CONT); do
                if [ "$1" = "same" ]
                then
                    FILE_NAME=text1
                    NEW_LOG_PATH=${LOG_PATH}-sameAPP-sameFile-BS${BS}-QD${QD}
                else
                    FILE_NAME=text${CONT_ID}
                    NEW_LOG_PATH=${LOG_PATH}-sameAPP-diffFile-BS${BS}-QD${QD}
                fi

                mkdir -p $NEW_LOG_PATH
                FIO_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_CONC${NUM_CONT}_CONT${CONT_ID}.summary
                TS_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_CONC${NUM_CONT}_CONT${CONT_ID}
                docker exec cont$CONT_ID \
                    fio --name test --direct=1 --ioengine=libaio --iodepth=$QD \
                    --filename=$MOUNT_PATH/$FILE_NAME --rw=$JOB_TYPE --bs=$BS \
                    --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME --output=$FIO_LOG_FILE &
                pids[${CONT_ID}]=$!
            done
            func_docker
        done
    done
}

if [[ $(docker ps -aq) ]]; then
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
fi

ARR_JOB=(randread)
func_same_simple "same"
#func_same_simple "diff"

#while true; do
#    echo "DONE!!!"
#done
