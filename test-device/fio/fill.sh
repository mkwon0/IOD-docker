#!/bin/bash

MAX=5
DEV=nvme0n1
DRIVER=overlay
BAKFS=ext4

#### Generate fio file (default: 5g, 4k, 32D)
for (( i=1; i <= $MAX; ++i ))
do
  rm -f ./fio-files/fill$i.fio
  sed '/filename/c\filename=/mnt/'$DEV'/text'$i'' ./fio-files/fill.fio > ./fio-files/fill$i.fio
done
cp -r /root/bench/fio/fio-files /mnt/fiologs/.

#### Execute fio application
mkdir -p /root/bench/fio/fio-results/$BAKFS-$DRIVER/fill
for (( i=1; i<= $MAX; ++i ))
do
  docker run --rm -v /mnt/$DEV:/mnt/$DEV:z \
                  -v /mnt/fiologs:/mnt/fiologs:z \
                  docker-fio /mnt/fiologs/fio-files/fill$i.fio > fio-results/$BAKFS-$DRIVER/fill/fill$i.out &
done
wait
