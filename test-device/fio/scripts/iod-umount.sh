#!/bin/bash

/sbin/mkfs.xfs -L /mnt/nvme1n1 /dev/nvme1n1
/sbin/mkfs.xfs -L /mnt/nvme1n2 /dev/nvme1n2
/sbin/mkfs.xfs -L /mnt/nvme1n3 /dev/nvme1n3
/sbin/mkfs.xfs -L /mnt/nvme1n4 /dev/nvme1n4

mkdir /mnt/nvme1n1
mkdir /mnt/nvme1n2
mkdir /mnt/nvme1n3
mkdir /mnt/nvme1n4

mount /dev/nvme1n1 /mnt/nvme1n1
mount /dev/nvme1n2 /mnt/nvme1n2
mount /dev/nvme1n3 /mnt/nvme1n3
mount /dev/nvme1n4 /mnt/nvme1n4
#mount /dev/sda /mnt/fiologs
