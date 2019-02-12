#!/bin/bash

/sbin/mkfs.xfs /dev/sda1
/sbin/mkfs.xfs /dev/sda2 
/sbin/mkfs.ext4 /dev/sda3
/sbin/mkfs.vfat /dev/sda4

fsck -N /dev/sda1 
fsck -N /dev/sda2
fsck -N /dev/sda3 
fsck -N /dev/sda4 

mkdir -p /mnt/fiologs
mkdir -p /var/lib/docker-xfs
mkdir -p /var/lib/docker-ext4
mkdir -p /var/lib/docker-fat32

mount /dev/sda1 /mnt/fiologs
mount /dev/sda2 /var/lib/docker-xfs
mount /dev/sda3 /var/lib/docker-ext4
mount /dev/sda4 /var/lib/docker-fat32

### Change docker image installation directory
CURRENT=docker-xfs
TARGET=docker-ext4
grep $CURRENT /etc/sysconfig/docker
sed -i "s/docker-ext4/docker-xfs/g" /etc/sysconfig/docker
systemctl restart docker
docker info | grep "Backing Filesystem"
