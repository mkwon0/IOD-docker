#!/bin/bash

cd /sys/kernel/debug/tracing
#echo 'do_swap_page'>set_ftrace_filter
echo function >current_tracer
#cat trace_pipe >/tmp/trace
cd -

docker run -itd \
	--privileged --oom-kill-disable=true \
	--name stress1 --memory="30m" --memory-swap="60m" --memory-swappiness="80" \
	--memory-swapfile="none" --entrypoint "/bin/bash" progrium/stress
