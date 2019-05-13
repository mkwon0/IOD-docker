#!/bin/bash

qemu-system-x86_64 -s -S \
	-kernel /usr/src/linux-5.0.7-swap/arch/x86_64/boot/bzImage \
	-smp 24 -boot c -m 2048M \
	-hda /home/mkwon/src/buildroot/output/images/rootfs.ext3 \
	-append "root=/dev/sda console=ttyS0" \
	-serial stdio -display none

#qemu-system-x86_64 -kernel /usr/src/linux-5.0.7-swap/arch/x86_64/boot/bzImage \
#	-smp 24 -boot c -m 2048M \
#	-drive file=/boot/initramfs-5.0.7-swap.img \
#	-append "root=/dev/sda rw console=tty0 console=ttyS0,115200 acpi=off" -serial stdio -display none
