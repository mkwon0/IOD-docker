#!/bin/bash

yum erase docker-ce
rm -rf /mnt/data/docker/*
rm -rf /var/run/docker.sock

yum install docker-ce
systemctl enable docker
systemctl start docker
systemctl status docker
