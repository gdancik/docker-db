#!/usr/bin/env bash

set -e

cleanup() {
  docker stop mydb123 || true
}

trap 'cleanup' ERR

if [ "$#" -ne 3 ]; then
    echo "Usage: copy-mongo-volume image volume db"
    echo
    echo "Create a mongo 'image' with a data export of the database 'db' from 'volume' that is stored in the entrypoint to be restored on container creation"
    exit
fi

image=$1
volume=$2
db=$3

echo "checking that volume exists"
a=`docker volume inspect $volume`

echo "creating docker container with mount to $sql"
docker run --rm --name mydb123 \
    -v $volume:/data/db \
    -d mongo 


echo "waiting 3 seconds..."
sleep 3

echo "dumping database..."
docker exec mydb123 bash -c "mongodump -d $db -o /docker-entrypoint-initdb.d/"

echo "writing startup script.."
docker exec mydb123 bash -c "cd /docker-entrypoint-initdb.d/ && echo 'mongorestore -d $db --dir=/docker-entrypoint-initdb.d/$db' >> init.sh"

echo "saving image"
docker commit mydb123 $image

echo "cleaning up..."
cleanup

echo "Image with data is saved to $image. You may now push to docker hub."
