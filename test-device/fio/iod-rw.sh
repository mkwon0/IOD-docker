#!/bin/bash
## p is pattern
## j is max

declare -a arr=(rw)

for p in "${arr[@]}"
do
  global_j=5
  for (( j=1; j <= $global_j; ++j ))
  do
    for (( i=1; i <= $j; ++i ))
    do
      echo $p$i.fio
      sed 's/text/text'$i'/g' ./fio-files/$p.fio > ./fio-files/$p$i.fio
      sed -i 's/logfile/corun'$j'-docker'$i'/g' ./fio-files/$p$i.fio
    done

    cp -r /root/bench/fio/fio-files /mnt/fiologs/.

    for (( i=1; i <= $j; ++i ))
    do 
      docker run --rm -v /mnt/nvme0n1:/mnt/nvme0n1:z \
                      -v /mnt/fiologs:/mnt/fiologs:z \
                      docker_fio /mnt/fiologs/fio-files/$p$i.fio > fio-results/$p/corun$j-docker$i.out &
    done
    wait
  done
done
