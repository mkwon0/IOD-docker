#!/bin/bash
TARGET_DEV="nvme1n1"
DEVICE="/dev/"$TARGET_DEV
MOUNT="/mnt/"$TARGET_DEV
MIN_BS=12  # 2^12 = 4096 = 4KB
MAX_BS=20  # 2^20 = 1048576 = 1MB
MIN_DEPTH=0 # 2^0 = 1
MAX_DEPTH=6 # 2^6 = 64
RUNTIME=15
RAMPTIME=0
LOG_MSEC=10
ARR_JOB=(randread read randwrite write)
SRC_VOLUME=resource
SRC_PATH="/mnt/"$SRC_VOLUME
LOG_PATH=$SRC_PATH/xfs-volume/fio-CONT1-NS1-QD-BS
IMAGE=fio

mkdir -p $LOG_PATH
for JOB_TYPE in "${ARR_JOB[@]}"
do
    for qorder in $(seq $MIN_DEPTH $MAX_DEPTH)
    do
        IODEPTH=$((2**$qorder))
        for bsorder in $(seq $MIN_BS $MAX_BS)
        do
            BS=$((2**$bsorder))
            FIO_LOG_FILE=$LOG_PATH/${JOB_TYPE}_$(($BS/1024))K_${IODEPTH}.summary
            TS_LOG_FILE=$LOG_PATH/${JOB_TYPE}_$(($BS/1024))K_${IODEPTH}

            docker run --rm \
                        --mount source=$TARGET_DEV,target=$MOUNT \
                        --mount source=$SRC_VOLUME,target=$SRC_PATH \
                        $IMAGE --name test --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$MOUNT/text1 --rw=$JOB_TYPE --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
                        --log_avg_msec=$LOG_MSEC --write_lat_log=$TS_LOG_FILE --write_bw_log=$TS_LOG_FILE --write_iops_log=$TS_LOG_FILE --output=$FIO_LOG_FILE
        done
    done
done

ARR_JOB=(readwrite randrw)
ARR_READ_RATIO=(10 20 30 40 50 60 70 80 90)
LOG_PATH=$SRC_PATH/xfs-volume/fio-CONT1-NS1-mix
IODEPTH=32
BS=4k

mkdir -p $LOG_PATH
for JOB_TYPE in "${ARR_JOB[@]}"
do
    for READ_RATIO in "${ARR_READ_RATIO}"
    do
        FIO_LOG_FILE=$LOG_PATH/${JOB_TYPE}_R${READ_RATIO}.summary
        TS_LOG_FILE=$LOG_PATH/${JOB_TYPE}_R${READ_RATIO}

        docker run --rm \
                    --mount source=$TARGET_DEV,target=$MOUNT \
                    --mount source=$SRC_VOLUME,target=$SRC_PATH \
                    $IMAGE --name test --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$MOUNT/text1 --rw=$JOB_TYPE --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
                    --rwmixread=$READ_RATIO --log_avg_msec=$LOG_MSEC --write_lat_log=$TS_LOG_FILE --write_bw_log=$TS_LOG_FILE --write_iops_log=$TS_LOG_FILE --output=$FIO_LOG_FILE
    done
done

while true
do
    echo "DONE!!!"
done
