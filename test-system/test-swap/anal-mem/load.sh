#!/bin/bash

DID=$(docker inspect nginx1 --format {{.Id}})
(timeout 200 docker stats --format \
  'CPU: {{.CPUPerc}}\tMEM: {{.MemPerc}}' $DID \
  | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' ; echo) \
  | gzip -c > monitor.log.gz
