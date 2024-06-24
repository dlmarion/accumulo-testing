#! /bin/bash

docker build --build-arg uid=$(id -u ${USER}) --build-arg gid=$(id -g ${USER}) -t timely-grafana .

rm -rf build_output
mkdir build_output
id=$(docker create ctg-stack)
docker cp $id:/opt/timely/lib-accumulo build_output/.
docker rm -v $id
