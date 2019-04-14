#!/bin/bash

systemctl stop docker
sed -i '/ExecStart/s/$/ -g \/mnt\/data\/docker/' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker
docker info | grep 'Docker Root Dir'
