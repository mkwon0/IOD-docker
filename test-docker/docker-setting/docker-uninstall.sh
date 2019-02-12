yum erase docker-ce
rm -rf /var/lib/docker-test/*
rm -rf /var/run/docker.sock

yum install docker-ce
systemctl enable docker
systemctl start docker
systemctl status docker
