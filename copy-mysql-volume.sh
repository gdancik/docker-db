#!/usr/bin/env bash

set -e

cleanup() {
  docker stop mydb123 || true
}

trap 'cleanup' ERR

if [ "$#" -ne 2 ]; then
    echo "Usage: copy-mysql-volume image volume"
    echo
    echo "Create a mysql 'image' with a mysql-no-volume data directory with data copied from 'volume'"
    exit
fi

image=$1
volume=$2

echo "checking that volume exists"
a=`docker volume inspect $volume`

echo "creating docker image $image"
docker build -t $image .

echo "creating docker container with mount to $sql"
docker run --rm --name mydb123 -e MYSQL_ROOT_PASSWORD=password \
    -v $volume:/mydata \
    -d $image 

echo "waiting 3 seconds..."
sleep 3

echo "copying data to /var/lib/mysql-no-volume"
docker exec mydb123 bash -c 'rm -Rf /var/lib/mysql-no-volume/* && cp -r /mydata/* /var/lib/mysql-no-volume && rm -Rf /mydbdata'

echo "saving image"
docker commit mydb123 $image

echo "cleaning up..."
cleanup

echo "Image with data is saved to $image. You may now push to docker hub."

