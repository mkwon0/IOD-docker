#!/bin/bash

## FIO parameters
ARR_RUN_TIME=(60 45 30 15)
ARR_DURATION=(60000 45000 30000 15000)
ARR_READ_RATIO=(10 20 30 40 50 60 70 80 90)

ARR_JOB=(rw randrw)
ARR_QD=(4)
ARR_BS=(4k)
LOG_MSEC=100
## Test parameters
DEV=nvme3n
SRC_VOL=resource

func_check_done()
{
    ARRAY=()
    for CONT_ID in $(seq 1 4);do 
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
				for RATIO in "${ARR_READ_RATIO[@]}";do
					
					SUMMARY_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/${JOB_TYPE}-QD${QD}-BS${BS}/READ_RATIO${RATIO}/summary
					LOG_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/${JOB_TYPE}-QD${QD}-BS${BS}/READ_RATIO${RATIO}/timelog
					STAT_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/${JOB_TYPE}-QD${QD}-BS${BS}/READ_RATIO${RATIO}/dockerstat
					BLKTRACE_PATH=/mnt/data/${SRC_VOL}/Interf-noCache/${JOB_TYPE}-QD${QD}-BS${BS}/READ_RATIO${RATIO}/blktrace
					mkdir -p $SUMMARY_PATH $LOG_PATH $STAT_PATH $BLKTRACE_PATH 
				
					ARR_DATE=($(date --date="180 seconds" +"%Y%m%d%H%M.%S") $(date --date="195 seconds" +"%Y%m%d%H%M.%S") $(date --date="210 seconds" +"%Y%m%d%H%M.%S") $(date --date="225 seconds" +"%Y%m%d%H%M.%S"))

					for NS in $(seq 1 4); do
						ARR_ID=$(($NS-1))
						FILE_NAME=${DEV}${NS}-cont1ID1
						LOG_FILE=${LOG_PATH}/${FILE_NAME}
						STAT_FILE=${STAT_PATH}/${FILE_NAME}.stat
						SUMMARY_FILE=${SUMMARY_PATH}/${FILE_NAME}.summary
					
						docker exec -d ID${NS} bash -c "fio --name ${DEV}${NS}-cont1ID1 --direct=1 --thread=1 --ioengine=libaio --iodepth=$QD \
													--rw=$JOB_TYPE --rwmixread=$RATIO --bs=$BS --time_based --runtime=${ARR_RUN_TIME[$ARR_ID]} --filename=/dev/${DEV}${NS} \
													--output=$SUMMARY_FILE --log_avg_msec=$LOG_MSEC --write_lat_log=$LOG_FILE --write_bw_log=$LOG_FILE --write_iops_log=$LOG_FILE | at -t ${ARR_DATE[$ARR_ID]}"
						docker exec -d ID${NS} bash -c "dockerstat 10 ${ARR_DURATION[$ARR_ID]} $STAT_FILE | at -t ${ARR_DATE[$ARR_ID]}" 
					done
	
					for NS in $(seq 1 4); do
						ARR_ID=$(($NS-1))
						startTime=$(date +"%Y%m%d%H%M.%S")	
						endTime=${ARR_DATE[${ARR_ID}]}
						timeToWait=$(echo "$endTime - $startTime"|bc)
						sleep $timeToWait

						BLKTRACE_FILE=${BLKTRACE_PATH}/${DEV}${NS}-cont1ID1.blktrace	
						blktrace -d /dev/${DEV}${NS} -w ${ARR_RUN_TIME[$ARR_ID]} -D $BLKTRACE_PATH > $BLKTRACE_FILE 2>&1 & 
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
