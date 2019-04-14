#!/bin/bash

### FIO parameters
#RUN_TIME=10
#ARR_JOB=(randread read randwrite write)
#ARR_QD=(1 32)
#ARR_BS=4k
#LOG_MSEC=10
#
### Test parameters
#MIN_NUM_CONT=2 # 2^2 = 4
#MAX_NUM_CONT=9 # 2^9 = 512
#DEV=nvme0n
#SRC_VOL=resource

## FIO parameters
ARR_RUN_TIME=(60 45 30 15)
ARR_DURATION=(60000 45000 30000 15000)
ARR_OFFSET=(0 1 2 3)

ARR_JOB=(read randread write randwrite)
ARR_QD=(4)
ARR_BS=(4k) 
LOG_MSEC=100
## Test parameters
DEV=nvme3n
SRC_VOL=resource

func_simple()
{
	for JOB_TYPE in "${ARR_JOB[@]}"; do
		for BS in "${ARR_BS[@]}";do
			for QD in "${ARR_QD[@]}"; do
				for OFFSET in "${ARR_OFFSET[@]}";do
					START_ID=$(($OFFSET+1))
					ARR_DATE=($(date --date="180 seconds" +"%Y%m%d%H%M.%S") $(date --date="195 seconds" +"%Y%m%d%H%M.%S") $(date --date="210 seconds" +"%Y%m%d%H%M.%S") $(date --date="225 seconds" +"%Y%m%d%H%M.%S"))
					for NS in $(seq 1 4); do
						DEV_ID=$(($NS+$OFFSET))
						if [ $DEV_ID -gt 4 ]; then
							DEV_ID=$(($DEV_ID%4))
						fi
						SUMMARY_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/startNS${START_ID}/${JOB_TYPE}-QD${QD}-BS${BS}/summary
						LOG_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/startNS${START_ID}/${JOB_TYPE}-QD${QD}-BS${BS}/timelog
						STAT_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/startNS${START_ID}/${JOB_TYPE}-QD${QD}-BS${BS}/dockerstat
						mkdir -p $SUMMARY_PATH $LOG_PATH $STAT_PATH

						ARR_ID=$(($NS-1))
						LOG_FILE=${LOG_PATH}/${DEV}${DEV_ID}-cont1ID1
						STAT_FILE=${STAT_PATH}/${DEV}${DEV_ID}-cont1ID1.stat
						
						docker exec -d ID${NS} bash -c "fio --name ${DEV}${DEV_ID}-cont1ID1 --thread=1 --ioengine=libaio --direct=1 --iodepth=$QD --rw=$JOB_TYPE --bs=$BS --time_based --runtime=${ARR_RUN_TIME[$ARR_ID]} --filename=/dev/${DEV}${DEV_ID} --output=${SUMMARY_PATH}/${DEV}${DEV_ID}-cont1ID1.summary --log_avg_msec=$LOG_MSEC --write_lat_log=$LOG_FILE --write_bw_log=$LOG_FILE --write_iops_log=$LOG_FILE | at -t ${ARR_DATE[$ARR_ID]}"

						docker exec -d ID${NS} bash -c "dockerstat 10 ${ARR_DURATION[$ARR_ID]} $STAT_FILE | at -t ${ARR_DATE[$ARR_ID]}" 
					done
		
					for NS in $(seq 1 4); do
						DEV_ID=$(($NS+$OFFSET))
						if [ $DEV_ID -gt 4 ]; then
							DEV_ID=$(($DEV_ID%4))
						fi
						ARR_ID=$(($NS-1))
						startTime=$(date +"%Y%m%d%H%M.%S")	
						endTime=${ARR_DATE[${ARR_ID}]}
						timeToWait=$(echo "$endTime - $startTime"|bc)
						sleep $timeToWait

						BLKTRACE_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/startNS${START_ID}/${JOB_TYPE}-QD${QD}-BS${BS}/blktrace
						mkdir -p $BLKTRACE_PATH
						BLKTRACE_FILE=${BLKTRACE_PATH}/${DEV}${DEV_ID}-cont1ID1.blktrace
						blktrace -d /dev/${DEV}${DEV_ID} -w ${ARR_RUN_TIME[$ARR_ID]} -D $BLKTRACE_PATH > $BLKTRACE_FILE 2>&1 & 
					done

					sleep 90s
					nvme flush /dev/nvme3n{1..4}
					echo 3 > /proc/sys/vm/drop_caches
				done
			done
		done
	done
}


func_simple

#while true
#do
#    echo "DONE!!!"
#done
