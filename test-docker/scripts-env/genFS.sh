#!/bin/baSH

#### Target devices
for (( id=0; id<4; ++id )); do
	for (( ns=1; ns<5; ++ns )); do
		mkfs.xfs /dev/nvme${id}${ns}
	done
done

#### Docker device
mkfs.xfs /dev/sdb
