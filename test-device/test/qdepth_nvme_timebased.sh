#!/bin/bash
CHARACTER="/dev/nvme1"
NAMESPACE=1
DEVICE=$CHARACTER"n"$NAMESPACE
MIN_BS=12  # 2^12 = 4096 = 4KB
MAX_BS=20  # 2^20 = 1048576 = 1MB
MIN_DEPTH=0 # 2^0 = 1
MAX_DEPTH=6 # 2^6 = 64
FLBAS=1    # LBA format index of nvme device
GREP="((read|write):)|(.lat.*: min)|(cpu.*:)"
RUNTIME=15
RAMPTIME=0
LOG_MSEC=10
FILL=false  # Fill before write tests

echo "Testing microbenchmark of "$DEVICE" using Flexible I/O tester"
echo "Min block size is "$((2**$MIN_BS))
echo "Max block size is "$((2**$MAX_BS))
echo "Min qdepth is "$((2**$MIN_DEPTH))
echo "Max qdepth is "$((2**$MAX_DEPTH))

if [ $FILL = true ];
then
  echo "Filling device enabled when write tests"
fi

echo ""

for qorder in $(seq $MIN_DEPTH $MAX_DEPTH)
do
  IODEPTH=$((2**$qorder))

  echo "Testing for qdepth "$IODEPTH

  # Write performance
  echo "Test for sequential write"
  for bsorder in $(seq $MIN_BS $MAX_BS)
  do
    BS=$((2**$bsorder))

    echo " Test for block size "$BS
    echo "  Formatting..."

    nvme format $DEVICE -l $FLBAS

    if [ $FILL = true ];
    then
      echo "  Filling..."
      fio --direct=1 --ioengine=libaio --iodepth=256 --filename=$DEVICE --name=test --rw=write --bs=1M > /dev/null
      echo "  Flushing..."
      nvme flush $CHARACTER -n $NAMESPACE
    fi

    fio --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$DEVICE --name=test --rw=write --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
    --log_avg_msec=$LOG_MSEC --write_lat_log=seqwrite_$(($BS/1024))K_$IODEPTH --write_bw_log=seqwrite_$(($BS/1024))K_$IODEPTH --write_iops_log=seqwrite_$(($BS/1024))K_$IODEPTH | grep -E "$GREP"

    echo ""
  done

  # Randwrite performance
  echo "Test for random write"
  for bsorder in $(seq $MIN_BS $MAX_BS)
  do
    BS=$((2**$bsorder))

    echo " Test for block size "$BS
    echo "  Formatting..."

    nvme format $DEVICE -l $FLBAS

    if [ $FILL = true ];
    then
      echo "  Filling..."
      fio --direct=1 --ioengine=libaio --iodepth=256 --filename=$DEVICE --name=test --rw=write --bs=1M > /dev/null
      echo "  Flushing..."
      nvme flush $CHARACTER -n $NAMESPACE
    fi

    fio --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$DEVICE --name=test --rw=randwrite --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
    --log_avg_msec=$LOG_MSEC --write_lat_log=randwrite_$(($BS/1024))K_$IODEPTH --write_bw_log=randwrite_$(($BS/1024))K_$IODEPTH --write_iops_log=randwrite_$(($BS/1024))K_$IODEPTH | grep -E "$GREP"

    echo ""
  done
done

# Filling
nvme format $DEVICE -l $FLBAS
echo "Filling..."
fio --direct=1 --ioengine=libaio --iodepth=256 --filename=$DEVICE --name=test --rw=write --bs=1M > /dev/null
echo "done"

for qorder in $(seq $MIN_DEPTH $MAX_DEPTH)
do
  IODEPTH=$((2**$qorder))

  echo "Testing for qdepth "$IODEPTH

  # Read performance
  echo "Test for sequential read"
  for bsorder in $(seq $MIN_BS $MAX_BS)
  do
    BS=$((2**$bsorder))

    echo " Test for block size "$BS
    echo "  Flushing..."

    nvme flush $CHARACTER -n $NAMESPACE

    fio --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$DEVICE --name=test --rw=read --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
    --log_avg_msec=$LOG_MSEC --write_lat_log=seqread_$(($BS/1024))K_$IODEPTH --write_bw_log=seqread_$(($BS/1024))K_$IODEPTH --write_iops_log=seqread_$(($BS/1024))K_$IODEPTH | grep -E "$GREP"

    echo ""
  done

  # Randread performance
  echo "Test for random read"
  for bsorder in $(seq $MIN_BS $MAX_BS)
  do
    BS=$((2**$bsorder))

    echo " Test for block size "$BS
    echo "  Flushing..."

    nvme flush $CHARACTER -n $NAMESPACE

    fio --direct=1 --ioengine=libaio --iodepth=$IODEPTH --filename=$DEVICE --name=test --rw=randread --bs=$BS --time_based --runtime=$RUNTIME --ramp_time=$RAMPTIME \
    --log_avg_msec=$LOG_MSEC --write_lat_log=randread_$(($BS/1024))K_$IODEPTH --write_bw_log=randread_$(($BS/1024))K_$IODEPTH --write_iops_log=randread_$(($BS/1024))K_$IODEPTH | grep -E "$GREP"

    echo ""
  done
done
