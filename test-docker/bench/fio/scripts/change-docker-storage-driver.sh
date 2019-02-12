#!/bin/bash
systemctl stop docker
vi /etc/systemd/system/multi-user.target.wants/docker.service
systemctl daemon-reload
systemctl start docker
