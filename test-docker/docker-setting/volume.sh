SRC_VOL=resource
SRC_PATH=/mnt/$SRC_VOL

curl -fsSL https://gist.githubusercontent.com/deviantony/bb3ff49aa117ea5294049e3470ef75f5/raw/c2a30b3398d62ddd34ceaee1dee67f184bca9e98/local-persist-install-nosudo.sh | bash

for (( idx=1; idx<5; ++idx )); do
    DEV=nvme1n$idx
    PATH=/mnt/$DEV
    docker volume create -d local-persist -o mountpoint=$PATH --name=$DEV
done

docker volume create -d local-persist -o mountpoint=$SRC_PATH --name=$SRC_VOL
docker volume ls
