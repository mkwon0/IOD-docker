#!/bin/bash
ARR_NUM_DEV=(1 2 4)
#ARR_IO_TYPE=(read randread write randwrite)
ARR_IO_TYPE=(randread write)
#ARR_IO_TYPE=(oltp_read_only oltp_write_only)
ARR_NUM_THREAD=(4 16 64 256)

ARR_FILE=("${ARR_IO_TYPE[@]}")
ARR_ROW=("${ARR_NUM_DEV[@]}")
ARR_COL=("${ARR_NUM_THREAD[@]}")

for FILE_TYPE in "${ARR_FILE[@]}"; do
	for ROW in "${ARR_ROW[@]}"; do
		for COL in "${ARR_COL[@]}"; do
			ANAL_PATH=/mnt/data/motiv/cont-fio/NS${ROW}/all/${FILE_TYPE}-${COL}
			for DEV_ID in $(seq 1 $ROW); do
				cd ${ANAL_PATH} && blkparse -i nvme1n${DEV_ID} \
				 -f "%5T.%9t, %p, %C, %a, %d, %N\n" \
				 -o blktrace-nvme1n${DEV_ID}.log && cd -
			done
			cd ${ANAL_PATH} && rm -rf nvme1n* && cd -
		done
	done
done
