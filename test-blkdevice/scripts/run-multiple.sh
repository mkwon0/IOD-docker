#!/bin/bash
MIN_NS=1
MAX_NS=4
MIN_BS=12 # 2^12 = 4KB
MAX_BS=20 # 2^20 = 1MB
MIN_DEPTH=0 # 2^0 = 1
MAX_DEPTH=6 # 2^6 = 64
GREP="((READ|WRITE):)|((read|write):)|(.lat.*: min)|(cpu.*:)"
#RW_TYPE=( read randread write randwrite )
#RW_TYPE=( read "random read" "write" "random write")
RW_TYPE=( randwrite )
 
echo "Testing microbenchmark of "$DEVICE" using Flexible I/O tester"
echo "Min block size is "$((2**$MIN_BS))
echo "Max block size is "$((2**$MAX_BS))
echo "Min qdepth is "$((2**$MIN_DEPTH))
echo "Max qdepth is "$((2**$MAX_DEPTH))


for RW in "${RW_TYPE[@]}"
do
  echo "Test for "$RW

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
        nvme flush /dev/nvme1n$id 
      done
   
      RW=$RW BSIZE=$BS DEPTH=$IODEPTH fio multiple.fio | grep -E "$GREP" 
      echo ""

    done 
  done
done
