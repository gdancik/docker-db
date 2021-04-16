#!/usr/bin/env bash

set -e

cleanup() {
  docker stop mydb123
  docker volume rm delete_me
}

trap 'cleanup' ERR

if [ "$#" -ne 4 ]; then
    echo "Usage: create-db image sql_dir timeout wait"
    echo
    echo "Creates a database image named 'image' from sql files in 'sql_dir' (must be an absolute path)"
    echo "Database creation can take a while. We wait 'timeout' seconds and retry every 'wait' seconds"
    exit
fi

image=$1
sql=$2
timeout=$3
sleeptime=$4

### Check if sql directory exists ###
if [ ! -d $sql ]
then
    echo "Directory $sql DOES NOT exist (do you need an absolute path)."
    exit 9999 # die with error code 9999
fi


echo "creating docker image $image"
docker build -t $image .

echo "creating docker container with mount to $sql"
docker run --rm --name mydb123 -e MYSQL_ROOT_PASSWORD=password \
    -v $sql:/docker-entrypoint-initdb.d \
    -v delete_me:/var/lib/mysql/\
    -d $image 

echo "waiting 10 seconds..."
sleep 10

x=0
while [ $x -le $timeout ]
do
  d=`date`
  echo "[$d] -- checking database ($x / $timeout)"
  num=`docker logs mydb123 2>&1 | grep "X Plugin ready for connections" | wc -l`

  if [ $num -eq 2 ]; then

      echo
      echo "database setup complete -- updating image $image"
      docker commit mydb123 $image

      echo "stopping container and removing volume"
      cleanup
      echo
      echo "the following image has been created: $image"
      exit
  fi 
 
  sleep $sleeptime

  x=$(( $x + $sleeptime ))
done

echo
echo "ERROR: database creation has timed out. A container mydb123 from $image is still running."
echo "You may want to wait for database creation to complete and then run 'docker commit mydb123 $image' to save the image."
echo    
echo "In any case, run the following to stop the container and remove the associated volume:"
echo "  docker stop mydb123"
echo "  docker volume rm delete_me"

