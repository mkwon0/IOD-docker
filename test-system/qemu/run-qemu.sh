#!/bin/bash

KERNEL_PATH=/usr/src/linux-5.0.7-swap

## one time setup
#cd $KERNEL_PATH
#mkinitrd -o ramdisk.img --force
#echo "add-auto-load-safe-path $KERNEL_PATH/scripts/gdb/vmlinux-gdb.py" >> ~/.gdbinit 

## one time kernel setup
#cd $KERNEL_PATH 
#./scripts/config -e DEBUG_INFO -e GDB_SCRIPTS

## each debug session run
#qemu-system-x86_64 \
#-kernel ${KERNEL_PATH}/arch/x86_64/boot/bzImage \
#-nographic \
#-append "console=ttys0 nokaslr" \
#-initrd /boot/initramfs-5.0.7.img \
#-m 512 \
#--enable-kvm \
#--cpu host \
#-s -S &


qemu-system-x86_64 -nographic \
-m 0124 \
-kernel ${KERNEL_PATH}/arch/x86_64/boot/bzImage \
-drive file=CentOS6.x-AMD64-root_fs.bz2 \ 
-enable-kvm -serial pty \
-append "kgdboc=ttyS0,115200 kgdbwait" \
root=/dev/sda2 
