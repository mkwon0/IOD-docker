#!/bin/bash

sed -i "s/host = graphite/host = $GRAPHITE_HOST/g" /etc/diamond/diamond.conf
diamond

[ -z "$JOBFILES" ] && echo "Need to set JOBFILES" && exit 1;
echo "Running $JOBFILES"

fio $JOBFILES
