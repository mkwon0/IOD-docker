#!/bin/bash
MIN_NS=2
MAX_NS=2
MIN_BS=12 # 2^12 = 4KB
MAX_BS=12 # 2^20 = 1MB
MIN_DEPTH=0 # 2^0 = 1
MAX_DEPTH=0 # 2^6 = 64
GREP="((READ|WRITE):)|((read|write):)|(.lat.*: min)|(cpu.*:)"
 
echo "Testing microbenchmark of "$DEVICE" using Flexible I/O tester"
echo "Min block size is "$((2**$MIN_BS))
echo "Max block size is "$((2**$MAX_BS))
echo "Min qdepth is "$((2**$MIN_DEPTH))
echo "Max qdepth is "$((2**$MAX_DEPTH))

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
   
    BSIZE=$BS DEPTH=$IODEPTH fio single.fio | grep -E "$GREP" 
    echo ""

  done 
done
