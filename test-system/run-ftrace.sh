#!/bin/bash

echo *:* > /sys/kernel/debug/tracing/set_event
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
fio --ioengine=libaio --name=test --thread=1 --iodepth=1 --rw=read --bs=4k --time_based --direct=1 --runtime=10 --filename=/dev/nvme0n1
#echo none > /sys/fs/cgroup/memory/docker/0757ce32ba48b5559a1a304f85525f33f8f324594683881d94f50b07e41e1b6c/memory.swapfile
#swapon -o private -L test
#echo 0 > /sys/kernel/debug/tracing/tracing_on
# vim /sys/kernel/debug/tracing/trace
