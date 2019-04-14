#!/bin/bash
./run-multiple.sh read > resultMax-read.txt
./run-multiple.sh randread > resultMax-randread.txt
./run-multiple.sh write > resultMax-write.txt
./run-multiple.sh randwrite > resultMax-randwrite.txt
