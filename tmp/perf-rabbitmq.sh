#!/bin/bash

/home/mkwon/src/rabbitmq-perf-test-2.8.1/bin/runjava com.rabbitmq.perf.PerfTest -h amqp://test:test@localhost:5672 -x 1 -y 2 -u "throughput-test-1" -a --id “test 1”
