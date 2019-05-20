#!/bin/bash

OUTPUT_PERCENT=percent.log
OUTPUT_GNUPLOT=gnuplot.log
OUTPUT_SUMMARY=ab.log
HOST_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' nginx1)

#docker run --name=nginx1 -P -d nginx:1.16
#ab -v 2 -t 10 -n 1000000 -c 1000 -e $OUTPUT_PERCENT -g $OUTPUT_GNUPLOT http://localhost:${HOST_PORT}/ > $OUTPUT_SUMMARY
ab -v 2 -t 10 -n 1000000 -c 1000 -s 600 -p post_loc.txt -T application/json -H 'Authorization: Token abcd1234' -e $OUTPUT_PERCENT -g $OUTPUT_GNUPLOT http://localhost:${HOST_PORT}/ > $OUTPUT_SUMMARY
