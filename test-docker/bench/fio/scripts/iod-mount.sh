#!/bin/bash

for (( i=1; i <= 4; ++i ))
do
  #umount /mnt/nvme0n$i
  #fstransform /dev/nvme0n$i ext4 
  mount /dev/nvme0n$i /mnt/nvme0n$i
done
