#!/bin/bash
## p is pattern
## j is max

#declare -a arr=(rw rr)
declare -a arr=(rw)

for p in "${arr[@]}"
do
  global_j=4
  for (( j=3; j <= $global_j; ++j ))
  do
    for (( i=1; i <= $j; ++i ))
    do
      echo $p$i.fio
      sed 's/nvme1n1/nvme1n'$i'/g' ./fio-files/$p.fio > ./fio-files/$p$i.fio
      sed -i 's/logfile/corun'$j'-ns'$i'/g' ./fio-files/$p$i.fio
    done

    cp -r /root/bench/fio/fio-files /mnt/fiologs/.

    echo 1 > /sys/kernel/debug/tracing/function_profile_enabled
    for (( i=1; i <= $j; ++i ))
    do 
      docker run --rm -v /mnt/nvme1n$i:/mnt/nvme1n$i:z \
                      -v /mnt/fiologs:/mnt/fiologs:z \
                      docker_fio /mnt/fiologs/fio-files/$p$i.fio > fio-results/$p/corun$j-ns$i.out &
    done
    wait
    cp /sys/kernel/debug/tracing/trace_stat/function0 ftrace-$p-corun$j.txt
    echo 0 > /sys/kernel/debug/tracing/function_profile_enabled
  done
done
