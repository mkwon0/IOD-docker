#!/bin/bash

## FIO parameters
RUN_TIME=15
ARR_JOB=(read write randread randwrite)
ARR_QD=(1 4 16 64)
ARR_BS=(4k 16k 64k)
LOG_MSEC=100

## Test parameters
MIN_NUM_CONT=2
MAX_NUM_CONT=5
DEV=nvme3n
DEV_ID=1
SRC_VOL=resource
IMAGE=fio-centos

func_simple()
{
	for JOB_TYPE in "${ARR_JOB[@]}"; do
		for BS in "${ARR_BS[@]}"; do
			for QD in "${ARR_QD[@]}";do
				mkdir -p /mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}
				mkdir -p /mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/summary
				mkdir -p /mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/timelog
				mkdir -p /mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/dockerstat
				mkdir -p /mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace
				
				for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT); do
					NUM_CONT=$((2**$numcont))
					DATE_FIO=$(date --date="3 minutes" +"%Y%m%d%H%M.%S")

					for CONT_ID in $(seq 1 $NUM_CONT); do
						LOG_FILE=/mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/timelog/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}
						STAT_FILE=/mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/dockerstat/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.stat
						SUMMARY_FILE=/mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/summary/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.summary

						docker exec -d ID${CONT_ID} bash -c "fio --name cont${NUM_CONT}ID${CONT_ID} --thread=1 \
							--ioengine=libaio --iodepth=$QD --rw=$JOB_TYPE --bs=$BS --time_based \
							--runtime=$RUN_TIME --filename=/dev/${DEV}${DEV_ID} \
							--output=$SUMMARY_FILE --log_avg_msec=$LOG_MSEC --write_lat_log=$LOG_FILE --write_bw_log=$LOG_FILE --write_iops_log=$LOG_FILE | at $DATE_FIO"
						docker exec -d ID${CONT_ID} bash -c "dockerstat 10 15000 $STAT_FILE | at $DATE_FIO"
					done

					## Blktrace scheduling
					startTime=$(date +"%Y%m%d%H%M.%S")
					endTime=$DATE_FIO
					timeToWait=$(echo "$endTime - $startTime"|bc)
					sleep $timeToWait
					BLKTRACE_PATH=/mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace/
					BLKTRACE_FILE=/mnt/data/${SRC_VOL}/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.blktrace
					blktrace -d /dev/${DEV}${DEV_ID} -w $RUN_TIME -D $BLKTRACE_PATH > $BLKTRACE_FILE 2>&1 &	
		
					sleep 1m
					nvme flush /dev/nvme3n{1..4}
					echo 3 > /proc/sys/vm/drop_caches
				done
			done
		done
	done
}

func_simple
