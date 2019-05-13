#!/bin/bash

## FIO parameters
RUN_TIME=15
#ARR_JOB=(read write randread randwrite)
#ARR_QD=(4 16 32 64)
#ARR_BS=(4k 16k 32k 64k)
LOG_MSEC=100

ARR_JOB=(read)
ARR_QD=(1)
ARR_BS=(4k)

## Test parameters
MIN_NUM_CONT=0
MAX_NUM_CONT=0
#MAX_NUM_CONT=9
DEV=nvme1n
DEV_ID=1
SRC_VOL=resource
IMAGE=fio-centos

func_simple()
{
	for JOB_TYPE in "${ARR_JOB[@]}"; do
		for BS in "${ARR_BS[@]}"; do
			for QD in "${ARR_QD[@]}";do
				
				for numcont in $(seq $MIN_NUM_CONT $MAX_NUM_CONT); do
					NUM_CONT=$((2**$numcont))

					for CONT_ID in $(seq 1 $NUM_CONT); do
						docker exec ID${CONT_ID} bash -c "fio --name cont${NUM_CONT}ID${CONT_ID} --thread=1 \
							--ioengine=libaio --iodepth=$QD --rw=$JOB_TYPE --bs=$BS --time_based --direct=1 \
							--runtime=$RUN_TIME --filename=/dev/${DEV}${DEV_ID} "
					done

					ARRAY=()
					### Check fio and dockerstat is done or not
					for CONT_ID in $(seq 1 $TOTAL_NUM_CONT); do
						ARRAY+=(${CONT_ID})
					done
								
#					while [ ${#ARRAY[@]} != 0 ]; do
#						idx=0
#						for CONT_ID in ${ARRAY[@]}; do
#							docker top ID${CONT_ID} | grep -q 'fio'
#							if [ $? == 1 ]; then ## if not exit
#								unset ARRAY[$idx]
#							fi
#							idx=$(($idx+1))
#						done
#					done
		
					sleep 20s
					nvme flush /dev/nvme1n{1..4}
					echo 3 > /proc/sys/vm/drop_caches
				done
			done
		done
	done
}

func_simple
