#!/bin/bash


docker stop $(docker ps -aq) && docker rm $(docker ps -aq)
IO_TYPE=oltp_read_only
OPTIONS="--threads=1 --events=100000 --time=0 \
         --table-size=1000000 --db-driver=mysql \
         --mysql-host=0.0.0.0 \
         --mysql-user=root --mysql-password=root \
         --mysql-ignore-errors="all" \
         --histogram "


echo "generate docker container"
docker pull mysql/mysql-server:8.0

docker run --name=mysql1 -m 400m \
	 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -p 3307:3306 -d mysql/mysql-server:8.0


docker exec mysql1 mysql -uroot -p'root' -e "ALTER USER root IDENTIFIED WITH mysql_native_password BY 'root';create database sbtest1;"
/usr/local/bin/sysbench $IO_TYPE $OPTIONS --mysql-port=3307 --mysql-db=sbtest1 prepare &
pid=$!

echo "" > stats
while true; do
	sleep 1
	sample="$(ps -o rss= $pid 2> /dev/null)" || break
	
	docker stats --no-stream --format "{{.MemUsage}} {{.Name}} {{.Container}}" | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0 }' >> stats
done

for containerid in `awk '/.+/ { print $7 }' stats | sort | uniq`; do
	grep "$containerid" stats | sort -r -k3 | tail -n 1
done
