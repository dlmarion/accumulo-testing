#!/bin/bash

ACCUMULO_SRC_DIR=~/git/accumulo
ACCUMULO_TESTING_DIR=~/git/accumulo-testing

cd $ACCUMULO_SRC_DIR
mvn clean install -PskipQA

cd $ACCUMULO_TESTING_DIR
mvn clean
./bin/build
docker build --build-arg HADOOP_HOME=/opt/accumulo-testing/hadoop/hadoop-3.3.1 --build-arg HADOOP_USER_NAME=hadoop -t accumulo-testing .
docker tag accumulo-testing:latest accumulosst.azurecr.io/sst/accumulo-testing
docker image prune -f
az acr login -n accumulosst
docker push accumulosst.azurecr.io/sst/accumulo-testing
