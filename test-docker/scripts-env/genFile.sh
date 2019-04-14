#!/bin/bash


for (( idx=1; idx <5; ++idx ))
do
	dev=nvme1n${idx}
	for (( num=1; num < 257; ++num ))
	do
		fallocate -l 1700M /mnt/${dev}/text${num} 
	done 
done
