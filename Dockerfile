# modified from: https://medium.com/@stevenlandow/persist-share-dev-mysql-data-in-a-docker-image-with-commit-f9aa9910be0a

# theres gotta be a cleaner way to do this where it
# doesn't still create the volume on /var/lib/mysql volumeFROM mysql:5.7

FROM mysql:8.0.19

RUN mkdir /var/lib/mysql-no-volume
CMD ["--datadir", "/var/lib/mysql-no-volume"]


