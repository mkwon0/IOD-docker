#!/bin/bash

curl -fsSL https://gist.githubusercontent.com/deviantony/bb3ff49aa117ea5294049e3470ef75f5/raw/c2a30b3398d62ddd34ceaee1dee67f184bca9e98/local-persist-install-nosudo.sh | bash

#### Generate disk volume
for (( id=0; id<4; ++id )); do
	for (( ns=1; ns<5; ++ns )); do
		DEV=nvme${id}n${ns}
		PATH=/mnt/$DEV
		docker volume create -d local-persist -o mountpoint=$PATH --name=$DEV
	done
done

#### Generate source volume
SRC_VOL=resource
SRC_PATH=/mnt/data/$SRC_VOL

docker volume create -d local-persist -o mountpoint=$SRC_PATH --name=$SRC_VOL
docker volume ls
