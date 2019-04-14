#!/bin/bash

## Test parameters
NUM_CONT=$1
SRC_VOL=resource
IMAGE=fio-centos

func_genCont()
{
	NUM_CONT=$((2**NUM_CONT))
	for CONT_ID in $(seq 1 $NUM_CONT); do
		echo "create ID$CONT_ID"
		docker run --network none -itd --privileged \
			--name ID${CONT_ID} \
			--mount type=bind,source=/etc/localtime,target=/etc/localtime \
			--mount source=$SRC_VOL,target=/mnt/data/$SRC_VOL \
			--device=/dev/nvme1n1 --device=/dev/nvme1n2 \
			--device=/dev/nvme1n3 --device=/dev/nvme1n4 \
			$IMAGE /bin/bash
	done
}

func_genCont
