#!/bin/bash

SWAP=/home/mkwon/swapfile
dd if=/dev/zero of=$SWAP bs=4K count=1024
chmod 600 $SWAP
mkswap -L swapfile $SWAP
