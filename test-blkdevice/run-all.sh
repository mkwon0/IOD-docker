#!/bin/bash
MIN_DEV=0
MAX_DEV=3
MIN_NS=1
MAX_NS=4
MIN_BS=12 # 2^12 = 4KB
MAX_BS=20 # 2^20 = 1MB
MIN_DEPTH=0 # 2^0 = 1
MAX_DEPTH=6 # 2^6 = 64
GREP="((READ|WRITE):)|((read|write):)|(.lat.*: min)|(cpu.*:)"
#RW_TYPE=( read randread write randwrite )
#RW_TYPE=( read "random read" "write" "random write")
RW_TYPE=( $1 )
 
echo "Testing microbenchmark of "$DEVICE" using Flexible I/O tester"
echo "Min block size is "$((2**$MIN_BS))
echo "Max block size is "$((2**$MAX_BS))
echo "Min qdepth is "$((2**$MIN_DEPTH))
echo "Max qdepth is "$((2**$MAX_DEPTH))
echo "Min device is "$MIN_DEV
echo "Max device is "$MAX_DEV
echo "Min namespace is "$MIN_NS
echo "Max namespace is "$MAX_NS

for DEV in $(seq $MIN_DEV $MAX_DEV)
do
  echo "Test for device "$DEV
  for RW in "${RW_TYPE[@]}"
  do
    echo "Test for type "$RW
    for qorder in $(seq $MIN_DEPTH $MAX_DEPTH)
    do
      IODEPTH=$((2**$qorder))
      echo "Testing for qdepth "$IODEPTH

      for bsorder in $(seq $MIN_BS $MAX_BS)
      do
        BS=$((2**$bsorder))
    
        echo " Test for block size "$BS
        echo "  Flushing..."
      
        for id in $(seq $MIN_NS $MAX_NS)
        do
          echo " Test for namespace "$id 
          nvme flush /dev/nvme$DEV\n$id
          RW=$RW BSIZE=$BS DEPTH=$IODEPTH DEVN=$DEV NSN=$id fio jobfiles/single.fio | grep -E "$GREP"
          echo "" 
        done
      done
    done 
  done
done
