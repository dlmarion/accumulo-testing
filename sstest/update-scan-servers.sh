#!/bin/bash

ACCUMULO_SRC_DIR=~/git/accumulo
ACCUMULO_DOCKER_DIR=~/git/accumulo-docker

cd $ACCUMULO_SRC_DIR
mvn clean package -DskipTests
cp assemble/target/accumulo-2.1.0-SNAPSHOT-bin.tar.gz $ACCUMULO_DOCKER_DIR

cd $ACCUMULO_DOCKER_DIR
docker build --build-arg ACCUMULO_VERSION=2.1.0-SNAPSHOT --build-arg ACCUMULO_FILE=accumulo-2.1.0-SNAPSHOT-bin.tar.gz   --build-arg HADOOP_VERSION=3.3.2 --build-arg HADOOP_FILE=hadoop-3.3.2.tar.gz   --build-arg ZOOKEEPER_VERSION=3.5.9 --build-arg ZOOKEEPER_FILE=apache-zookeeper-3.5.9-bin.tar.gz -t accumulo .
docker tag accumulo:latest accumulosst.azurecr.io/sst/accumulo
docker image prune -f
az acr login -n accumulosst
docker push accumulosst.azurecr.io/sst/accumulo

kubectl rollout restart deployment/accumulo-scanserver


