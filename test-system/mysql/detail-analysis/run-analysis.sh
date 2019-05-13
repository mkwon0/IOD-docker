#!/bin/bash

for i in $(seq 2 2); do
	echo analysis results$i
	cd results$i
	echo nvme0n1
	awk '$3 == "(null)," { print $2 }' blktrace-nvme0n1.log | sort | uniq -c | sort -nr
	for j in $(seq 2 $i); do
		echo nvme0n$j
		awk '$5 == "WS," { print $2 }' blktrace-nvme0n${j}.log | sort | uniq -c | sort -nr
	done
	cd ../
done
