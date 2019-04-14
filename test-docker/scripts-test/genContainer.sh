#!/bin/bash

## Test parameters
NUM_CONT=$1
DEV=nvme3n1
SRC_VOL=resource
IMAGE=fio-centos

func_genCont()
{
	NUM_CONT=$((2**NUM_CONT))
	for CONT_ID in $(seq 257 $NUM_CONT); do
		echo "create ID$CONT_ID"
		docker run --network none -itd --privileged \
			--name ID${CONT_ID} \
			--mount type=bind,source=/etc/localtime,target=/etc/localtime \
			--mount source=$SRC_VOL,target=/mnt/data/$SRC_VOL \
			--device=/dev/nvme3n1 --device=/dev/nvme3n2 \
			--device=/dev/nvme3n3 --device=/dev/nvme3n4 \
			$IMAGE /bin/bash
	done
}

func_genCont
