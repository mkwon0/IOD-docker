#!/bin/bash

ARR_FS=(xfs ext4)
ARR_CONC=($(seq 1 1 5))
ARR_JOB=(rr sr rw sw)
ARR_STORAGE=(bind volume)

for (( FS_IDX=0; FS_IDX < ${#ARR_FS[@]}; ++FS_IDX )); do
	BFS=${ARR_FS[FS_IDX]}
	echo $BFS
	for STORAGE in "${ARR_STORAGE[@]}"; do
		echo $STORAGE
		for JOB in "${ARR_JOB[@]}"; do
			echo $JOB
			for NUM_CONC in "${ARR_CONC[@]}"; do
				echo $NUM_CONC
				for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID )); do
					LOG_FILE=/mnt/resource/iod/$BFS/synthetic/$STORAGE/conc$NUM_CONC/single/diff/$JOB/fiolog$CONC_ID
					python analysis-stat.py $LOG_FILE
				done
			done
		done
	done
done
