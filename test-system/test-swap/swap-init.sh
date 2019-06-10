#!/bin/bash

## comment out of private
awk '$4 ~ /private/ {print substr($0,2);} $4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak && mv /etc/fstab.bak /etc/fstab
cat /etc/fstab | grep private

swapon -a
cat /proc/swaps | grep private

## comment private
awk '$4 ~ /private/ {print "#"$0} $4 !~/private/ {print }' /etc/fstab > /etc/fstab.bak && mv /etc/fstab.bak /etc/fstab
cat /etc/fstab | grep private
