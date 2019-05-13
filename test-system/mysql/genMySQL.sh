#!/bin/bash

NUM_CONT=$1
ARR_NUM_MYSQL=($(seq 1 $NUM_CONT))
DOCKER_ROOT=/mnt/nvme0n1/docker

docker_init() {
	docker stop $(docker ps -aq)
	docker rm $(docker ps -aq)
	for i in "${ARR_NUM_MYSQL[@]}"; do
		if [ $i -eq 1 ]; then
			VOL_ID=1
		else
			TMP=$((i%3))
			if [ $TMP -eq 2 ]; then
				VOL_ID=2
			elif [ $TMP -eq 0 ]; then
				VOL_ID=3
			elif [ $TMP -eq 1 ]; then
				VOL_ID=4
			fi
		fi
		DIR=/mnt/nvme0n${VOL_ID}/mysql$i
		rm -rf $DIR
		mkdir -p $DIR
	done
#	systemctl stop docker
#	umount $DOCKER_ROOT/overlay2
#	rm -rf $DOCKER_ROOT
#	systemctl start docker
}

docker_healty () {
    while [ "$(docker ps -a | grep -c starting)" = 1 ]; do
        sleep 0.1;
    done;
}

docker_volume_gen() {
    for i in "${ARR_NUM_MYSQL[@]}"; do 
		DIR=/mnt/nvme0n$i/mysql$i
		rm -rf $DIR
		mkdir -p $DIR
		docker volume rm volume$i 
#        docker volume create -d local-persist -o mountpoint=$DIR --name=volume$i
    done
}

docker_mysql_gen() {
    for i in "${ARR_NUM_MYSQL[@]}"; do
        HOST_PORT=$((3305+$i))
		if [ $i -eq 1 ]; then
			VOL_ID=1
		else
			TMP=$((i%3))
			if [ $TMP -eq 2 ]; then
				VOL_ID=2
			elif [ $TMP -eq 0 ]; then
				VOL_ID=3
			elif [ $TMP -eq 1 ]; then
				VOL_ID=4
			fi
		fi
        docker run --name=mysql$i -m 270m --oom-kill-disable -v /mnt/nvme0n${VOL_ID}/mysql$i:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -p $HOST_PORT:3306 -d mysql/mysql-server:8.0
	done
	sleep 20
	docker_healty
	sleep 30

	for i in "${ARR_NUM_MYSQL[@]}"; do
		HOST_PORT=$((3305+$i))
		docker exec mysql$i mysql -uroot -p'root' -e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest$i;"
	done
}

docker_init
#docker_volume_gen
docker_mysql_gen
