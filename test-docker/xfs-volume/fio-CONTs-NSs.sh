#!/bin/bash
TARGET_DEV="nvme1n2"
DEVICE="/dev/"$TARGET_DEV
MOUNT="/mnt/"$TARGET_DEV
IODEPTH=1
BS=4k
MIN_NUM_CONT=0  # 2^0 = 1
MAX_NUM_CONT=8  # 2^10 = 1024
RUNTIME=30
RAMPTIME=10
LOG_MSEC=10
SRC_VOLUME=resource
SRC_PATH="/mnt/"$SRC_VOLUME
IMAGE=fio
LOG_PATH=$SRC_PATH/xfs-volume/fio-CONTs-NSs

func_same_simple()
{
    ARR_JOB=(randread read randwrite write)
    for JOB_TYPE in "${ARR_JOB[@]}"
    do
        for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT)
        do
            NUM_CONT=$((2**$numcont))
            for CONT_ID in $(seq 1 $NUM_CONT)
            do
                FILE_NAME=text1
                NEW_LOG_PATH=${LOG_PATH}-two-sameAPP

                mkdir -p $NEW_LOG_PATH
                FIO_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_NS2_CONC${NUM_CONT}_CONT${CONT_ID}.summary
                TS_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_NS2_CONC${NUM_CONT}_CONT${CONT_ID}

                docker run -d --rm \
                    --mount source=$TARGET_DEV,target=$MOUNT \
                    --mount source=$SRC_VOLUME,target=$SRC_PATH \
                    $IMAGE --name test --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$MOUNT/$FILE_NAME --rw=$JOB_TYPE --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
                    --log_avg_msec=$LOG_MSEC --write_lat_log=$TS_LOG_FILE --write_bw_log=$TS_LOG_FILE --write_iops_log=$TS_LOG_FILE --output=$FIO_LOG_FILE
            done
            FIO_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_NS1.summary
            TS_LOG_FILE=$NEW_LOG_PATH/${JOB_TYPE}_NS1
            docker run -d --rm \
                --mount source="nvme1n1",target="/mnt/nvme1n1" \
                --mount source=$SRC_VOLUME,target=$SRC_PATH \
                $IMAGE --name test --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename="/mnt/nvme1n1" --rw=$JOB_TYPE --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
                --log_avg_msec=$LOG_MSEC --write_lat_log=$TS_LOG_FILE --write_bw_log=$TS_LOG_FILE --write_iops_log=$TS_LOG_FILE --output=$FIO_LOG_FILE
            docker wait $(docker ps -aq)
        done
    done
}

if [[ $(docker ps -aq) ]]
then
    docker kill $(docker ps -aq)
    docker rm $(docker ps -aq)
fi

func_same_simple

while true
do
    echo "DONE!!!"
done
