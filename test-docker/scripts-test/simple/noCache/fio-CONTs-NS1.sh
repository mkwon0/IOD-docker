#!/bin/bash

## FIO parameters
RUN_TIME=15
ARR_JOB=(read write randread randwrite)
ARR_QD=(256 512 1024 2048)
ARR_BS=(4k 16k 32k 64k 128k 256k 512k 1024k)

## Test parameters
MIN_NUM_CONT=0
MAX_NUM_CONT=9
DEV=nvme3n
DEV_ID=1
SRC_VOL=resource
IMAGE=fio-centos

func_simple()
{
	for JOB_TYPE in "${ARR_JOB[@]}"; do
		for BS in "${ARR_BS[@]}"; do
			for QD in "${ARR_QD[@]}";do
				mkdir -p /mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}
				mkdir -p /mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/summary
				mkdir -p /mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace
				
				for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT); do
					NUM_CONT=$((2**$numcont))
					DATE_FIO=$(date --date="3 minutes" +"%Y%m%d%H%M.%S")

					for CONT_ID in $(seq 1 $NUM_CONT); do
						STAT_FILE=/mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/dockerstat/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.stat
						SUMMARY_FILE=/mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/summary/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.summary

						docker exec -d ID${CONT_ID} bash -c "fio --name cont${NUM_CONT}ID${CONT_ID} --thread=1 \
							--ioengine=libaio --iodepth=$QD --rw=$JOB_TYPE --bs=$BS --time_based --direct=1 \
							--runtime=$RUN_TIME --filename=/dev/${DEV}${DEV_ID} --output=$SUMMARY_FILE | at -t at $DATE_FIO"
					done

					## Blktrace scheduling
					startTime=$(date +"%Y%m%d%H%M.%S")
					endTime=$DATE_FIO
					timeToWait=$(echo "$endTime - $startTime"|bc)
					sleep $timeToWait
					BLKTRACE_PATH=/mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace/
					BLKTRACE_FILE=/mnt/data/${SRC_VOL}/NS1-noCache/NS1/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace/${DEV}${DEV_ID}-cont${NUM_CONT}ID${CONT_ID}.blktrace
					blktrace -d /dev/${DEV}${DEV_ID} -w $RUN_TIME -D $BLKTRACE_PATH > $BLKTRACE_FILE 2>&1 &	

					ARRAY=()
					### Check fio and dockerstat is done or not
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
					nvme flush /dev/nvme3n{1..4}
#					echo 3 > /proc/sys/vm/drop_caches
				done
			done
		done
	done
}

func_simple
