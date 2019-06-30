#!/bin/bash

#PID=$(docker inspect --format '{{.State.Pid}}' mysql1)
#grep VmPeak /proc/$PID/status

"$@" &
pid=$!

echo "" > stats
while true; do
	sleep 0.01
	sample="$(ps -o rss= $pid 2> /dev/null)" || break
	docker stats --no-stream --format "{{.MemUsage}} {{.Name}} {{.Container}}" | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0 }' >> stats	
done

for containerid in `awk '/.+/ { print $7 }' stats | sort | uniq`
do
	grep "$containerid" stats | sort -r -k3 | tail -n 1
done
