systemctl stop docker
sed -i '/ExecStart/s/$/ -g \/var\/lib\/docker-test/' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker
docker info | grep 'Docker Root Dir'
