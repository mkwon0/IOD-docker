#!/bin/bash

max=4
for (( i=1; i <= $max; ++i ))
do
  sed 's/nvme1n1/nvme1n'$i'/g' ./fio-files/fill-2g.fio > ./fio-files/fill-2g-$i.fio
done

cp -r /root/bench/fio/fio-files /mnt/fiologs/.

for (( i=1; i<= $max; ++i ))
do
  docker run --rm -v /mnt/nvme1n$i:/mnt/nvme1n$i:z -v /mnt/fiologs:/mnt/fiologs:z \
             docker_fio /mnt/fiologs/fio-files/fill-2g-$i.fio > fio-results/fill/fill-2g-NS$i.out
done
