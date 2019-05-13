#!/bin/bash

#qemu-img create ubuntu11-server.img 128G

qemu-system-x86_64 -smp 4 -cpu host -m 1024 \
	-enable-kvm -cdrom ubuntu-11.04-server-i386.iso \
	ubuntu11-server.img -boot d

#qemu-system-x86_64 -enable-kvm -smp 4 -m 1024 \
#	-drive file=ubuntu.img,if=virtio,cache=none \
#	-netdev user,id=tcp22,hostfwd=tcp::7777-:22
