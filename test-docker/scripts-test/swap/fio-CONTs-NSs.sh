#!/bin/bash

## FIO parameters
RUN_TIME=100
ARR_JOB=(read)
ARR_QD=(1)
ARR_BS=(4k) 
LOG_MSEC=100
## Test parameters
MIN_NUM_CONT=7
MAX_NUM_CONT=7
DEV=nvme1n
SRC_VOL=resource
IMAGE=fio-centos

func_check_done()
{
	ARRAY=()
	for CONT_ID in $(seq 1 $TOTAL_NUM_CONT); do
		ARRAY+=(${CONT_ID})
	done

	while [ ${#ARRAY[@]} != 0 ]; do
		idx=0
		for CONT_ID in ${ARRAY[@]}; do
			docker top ID${CONT_ID} | grep -q 'fio\|dockerstat'
			if [ $? == 1 ]; then ## if not exit
				unset ARRAY[$idx]
			fi
			idx=$(($idx+1))
		done
	done
	sleep 20s
}

func_simple()
{
	for JOB_TYPE in "${ARR_JOB[@]}"; do
		for BS in "${ARR_BS[@]}";do
			for QD in "${ARR_QD[@]}"; do
				SUMMARY_PATH=/mnt/data/${SRC_VOL}/swap-2G/${JOB_TYPE}-QD${QD}-BS${BS}/summary
				TIMELOG_PATH=/mnt/data/${SRC_VOL}/swap-2G/${JOB_TYPE}-QD${QD}-BS${BS}/timelog
				STAT_PATH=/mnt/data/${SRC_VOL}/swap-2G/${JOB_TYPE}-QD${QD}-BS${BS}/dockerstat
				SWAP_PATH=/mnt/data/${SRC_VOL}/swap-2G/${JOB_TYPE}-QD${QD}-BS${BS}/swap
                mkdir -p $SUMMARY_PATH $TIMELOG_PATH $STAT_PATH

				for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT); do
					TOTAL_NUM_CONT=$((2**$numcont))
					NUM_CONT=$(($TOTAL_NUM_CONT/4))
					DATE_FIO=$(date --date="3 minutes" +"%Y%m%d%H%M.%S")

					for NS in $(seq 0 3); do
						DEV_ID=$(($NS+1))
						start=$(($NUM_CONT*$NS+1))
						end=$(($NUM_CONT*($NS+1)))
	
						for CONT_ID in $(seq $start $end); do
							INTERNAL_ID=$(($CONT_ID-$NS*$NUM_CONT))

							FILE_NAME=${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}
							LOG_FILE=${SUMMARY_PATH}/$FILE_NAME
							STAT_FILE=${STAT_PATH}/${FILE_NAME}.stat
							SWAP_FILE=${SWAP_PATH}/${FILE_NAME}.swap
							SUMMARY_FILE=${SUMMARY_PATH}/${FILE_NAME}.summary
							
							PID=$(docker inspect --format={{.State.Pid}} ID${CONT_ID})
							stat-per-process $PID 10 $RUN_TIME $SWAP_FILE | at $DATE_FIO
							docker exec -d ID${CONT_ID} bash -c "fio --name ${DEV}${DEV_ID}-cont${NUM_CONT}ID${INTERNAL_ID} \
								--thread=1 --ioengine=libaio --iodepth=$QD --rw=$JOB_TYPE --bs=$BS --time_based \
								--runtime=$RUN_TIME --filename=/dev/${DEV}${DEV_ID} --output=$SUMMARY_FILE \
								--log_avg_msec=$LOG_MSEC --write_lat_log=$LOG_FILE --write_bw_log=$LOG_FILE --write_iops_log=$LOG_FILE | at $DATE_FIO"
							docker exec -d ID${CONT_ID} bash -c "dockerstat 10 15000 $STAT_FILE | at $DATE_FIO"
						done
					done

					func_check_done
                    nvme flush /dev/nvme3n{1..4}
					echo 3 > /proc/sys/vm/drop_caches
				done
			done
		done
	done
}

func_simple
