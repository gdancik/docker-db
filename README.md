# docker-db

## Overview

This repo includes scripts for saving data to docker databases. In particular, volume database data can be saved directly to mysql and mongo docker images.

## Get the code
Get the code by running 

``` 
git clone https://github.com/gdancik/docker-db.git
```

## MySQL 

We use a framework that uses a slightly modified version of the [mysql](https://hub.docker.com/_/mysql) docker image that creates a database with data saved directly to the image. The following changes are made (H/T to [Steven Landow](https://medium.com/@stevenlandow/persist-share-dev-mysql-data-in-a-docker-image-with-commit-f9aa9910be0a)):

- a new directory, */var/lib/mysql-no-volume*, is created to store data
- this new directory is made the default data directory 

## Mongo 

For mongo, we store a data dump in the entrypoint directory, and the data is restored when a container is created.

## Creating a new database image


### Create a new database image using data from a previously created volume (MySQL and Mongo)

The following commands will create a new image from a volume.

For MySQL, use

```
./copy-mysql-volume.sh mydbimage volume
```

For Mongo, use

```
./copy-mongo-volume.sh mydbimage volume db
```

The arguments are:

- *mydbimage* is the name of the new image to create
- *volume* is a volume containing the data (i.e., a volume created from a previous mysql or mongo container)
- *db* is the name of the database (mongo only)

### Create the image from a data dump on your local machine (MySQL only)

First, you will need a directory containing your mysql data , e.g., a data dump. This directory will be mounted to */docker-entrypoint-initdb.d* and supported files (.sh, .sql and .sql.gz) are executed alphabetically when the image is created. Note that these files themselves are not saved to the image.

To create a new image with your data, run the following:

```
./create-db-from-entrypoint.sh mydbimage /path/to/mydbdata timeout wait
```

where

- *mydbimage* is the name of the new image to create
- */path/to/mydbdata* is an absolute path to the directory containing the data to add to the image
- *timeout* is the timeout, in seconds
- *wait* is the wait time, when checking that the database has been created.

For example, the command

```
./create-db.sh mydbimage /path/to/mydbdata 600 20
```

will create an image named *mydbimage* that contains data from *path/to/mydbdata*. Database creation will time out after 10 minutes (600 seconds), and the script will check every 20 seconds for whether the database creation is complete. 


### Launch the database (MySQL example)

You can now create a container which runs a mysql-server that includes your data. For example, we create the container and map the db to local port 3000, use

``` 
docker run -p 3000:3306 -e MYSQL_ROOT_PASSWORD=password mydbimage
```

### Launch the database for use with docker R clients (DCAST/CPP example)

You will need to connect to mysql using native authentication. In order to do this, turn ssl off and then allow *mysql_native_password* by running the commands below.

Launch the container with ssl turned off:

```
docker run -it -d --name dcast gdancik/dcast:try_data bash -c "docker-entrypoint.sh --datadir /var/lib/mysql-no-volume/ --ssl=off"
```

Allow native authentication:

```
docker exec -it dcast bash -c 'mysql -u root --password=password -e "ALTER USER \"root\" IDENTIFIED WITH mysql_native_password BY \"password\""'
```

This behavior is also documented here: https://github.com/gdancik/lamp-rm/blob/main/troubleshooting/mysql.md

For more information, see [https://hub.docker.com/_/mysql](https://hub.docker.com/_/mysql). Note that if you want to create a volume for the data directory, you now will need to map it to /var/lib/mysql-no-volume. Note that a volume will also be created for the original data directory /var/lib/mysql. To remove anonymous volumes automatically, use the --rm flag.

