#!/bin/bash

docker build -t docker_fio_fill .
docker run --rm -v /mnt/nvme0n1:/mnt/nvme0n1:z docker_fio_fill \
           root/fio-files/overlay-fill.fio > fio-results/overlay/fill.out
docker build -t docker_fio_rw .
docker run --rm -v /mnt/nvme0n1:/mnt/nvme0n1:z docker_fio_rw \
           root/fio-files/overlay-rw.fio > fio-results/overlay/rw.out
docker build -t docker_fio_rr .
docker run --rm -v /mnt/nvme0n1:/mnt/nvme0n1:z docker_fio_rr \
           root/fio-files/overlay-rr.fio > fio-results/overlay/rr.out
docker build -t docker_fio_mix .
docker run --rm -v /mnt/nvme0n1:/mnt/nvme0n1:z docker_fio_mix \
           root/fio-files/overlay-mix.fio > fio-results/overlay/mix.out
