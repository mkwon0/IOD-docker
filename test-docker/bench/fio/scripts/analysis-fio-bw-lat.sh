#!/bin/bash

for (( i=1; i <=$1; ++i ))
do 
  python analysis-stat.py ../fio-results/rr/corun$i-docker1.out randread
done
