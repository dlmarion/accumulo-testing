#! /bin/bash

until [[ -d ${efs_mount} && -f /usr/bin/wget && -f /usr/bin/g++ ]]; do
  echo "waiting for dependencies..."
  sleep 1m
done

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

SOURCES_DIR="${efs_mount}/sources"

cd ${efs_mount}
mkdir -p $SOURCES_DIR

#
# Download and configure Maven
#
MVN_URL="https://dlcdn.apache.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz"
MVN_SRC="$${SOURCES_DIR}/apache-maven-${maven_version}-bin.tar.gz"

if [ ! -f $MVN_SRC ]; then
  wget $MVN_URL -O $MVN_SRC
fi
if [ ! -d ${efs_mount}/apache-maven/apache-maven-${maven_version} ]; then
  mkdir -p ${efs_mount}/apache-maven
  tar zxf $MVN_SRC -C ${efs_mount}/apache-maven
  cat << 'END' >> ${efs_mount}/apache-maven/settings.xml
  <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
      <localRepository>${efs_mount}/apache-maven/repository</localRepository>
  </settings>
END
fi

#
# Download and Install ZooKeeper
#
ZK_URL="https://dlcdn.apache.org/zookeeper/zookeeper-${zookeeper_version}/apache-zookeeper-${zookeeper_version}-bin.tar.gz"
ZK_SRC="$${SOURCES_DIR}/apache-zookeeper-${zookeeper_version}-bin.tar.gz"

if [ ! -f $ZK_SRC ]; then
  wget $ZK_URL -O $ZK_SRC
fi
if [ ! -d ${efs_mount}/zookeeper/apache-zookeeper-${zookeeper_version}-bin ]; then
  mkdir -p ${efs_mount}/zookeeper
  tar zxf $ZK_SRC -C ${efs_mount}/zookeeper
fi

#
# Download and Install Hadoop
#
HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz"
HADOOP_SRC="$${SOURCES_DIR}/hadoop-${hadoop_version}.tar.gz"

if [ ! -f $HADOOP_SRC ]; then
  wget $HADOOP_URL -O $HADOOP_SRC 
fi
if [ ! -d ${efs_mount}/hadoop/hadoop-${hadoop_version} ]; then
  mkdir -p ${efs_mount}/hadoop
  tar zxf $HADOOP_SRC -C ${efs_mount}/hadoop
fi

#
# If Accumulo binary tarball provided, then untar it and use it
#
ACCUMULO_SRC="$${SOURCES_DIR}/accumulo-${accumulo_version}-bin.tar.gz"

if [ -f $ACCUMULO_SRC ]; then
  echo "Binary tarball found, untarring it..."
  mkdir -p ${efs_mount}/accumulo
  tar zxf $ACCUMULO_SRC -C ${efs_mount}/accumulo
else
#
# Download, build, and install Accumulo
  echo "Binary tarball not found, cloning Accumulo repo from ${accumulo_repo}"
  rm -rf $SOURCES_DIR/accumulo-repo
  cd $SOURCES_DIR
  git clone ${accumulo_repo} accumulo-repo
  cd accumulo-repo
  git checkout ${accumulo_branch_name}
  ${efs_mount}/apache-maven/apache-maven-${maven_version}/bin/mvn -s ${efs_mount}/apache-maven/settings.xml clean package -DskipTests -DskipITs
  mkdir -p ${efs_mount}/accumulo
  tar zxf assemble/target/accumulo-${accumulo_version}-bin.tar.gz -C ${efs_mount}/accumulo
fi

#
# OpenTelemetry dependencies
#
if [ ! -f ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/opentelemetry-javaagent-1.7.1.jar ]; then
  wget https://search.maven.org/remotecontent?filepath=io/opentelemetry/javaagent/opentelemetry-javaagent/1.7.1/opentelemetry-javaagent-1.7.1.jar -O ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/opentelemetry-javaagent-1.7.1.jar
fi
#
# Micrometer dependencies
#
if [ ! -f ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/accumulo-test-${accumulo_version}.jar ]; then
  if [ -f $SOURCES_DIR/accumulo-repo/test/target/accumulo-test-${accumulo_version}.jar ]; then
    cp $SOURCES_DIR/accumulo-repo/test/target/accumulo-test-${accumulo_version}.jar ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/.
  else
    echo "accumulo-test-${accumulo_version}.jar not found, metrics won't work..."
  fi
fi
if [ ! -f ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/micrometer-registry-statsd-1.7.4.jar ]; then
  wget https://search.maven.org/remotecontent?filepath=io/micrometer/micrometer-registry-statsd/1.7.4/micrometer-registry-statsd-1.7.4.jar -O ${efs_mount}/accumulo/accumulo-${accumulo_version}/lib/micrometer-registry-statsd-1.7.4.jar
fi

#
# Download and build Accumulo-Testing
#
TESTING_SRC="$${SOURCES_DIR}/accumulo-testing.zip"

cd ${efs_mount}
if [ -f $TESTING_SRC ]; then
  echo "Accumulo Testing tarball found, untarring it..."
  mkdir -p $SOURCES_DIR/accumulo-testing-repo
  tar zxf $TESTING_SRC -C $SOURCES_DIR/accumulo-testing-repo
else
  # Download, build, and install Accumulo Testing
  rm -rf $SOURCES_DIR/accumulo-testing-repo
  cd $SOURCES_DIR
  git clone ${accumulo_testing_repo} accumulo-testing-repo
  cd accumulo-testing-repo
  git checkout ${accumulo_testing_branch_name}
  ${efs_mount}/apache-maven/apache-maven-${maven_version}/bin/mvn -s ${efs_mount}/apache-maven/settings.xml clean package -DskipTests -DskipITs
fi

#
# Copy the configuration files to the correct places
#
cp ${efs_mount}/conf/zoo.cfg ${efs_mount}/zookeeper/apache-zookeeper-${zookeeper_version}-bin/conf/zoo.cfg
cp ${efs_mount}/conf/hdfs-site.xml ${efs_mount}/hadoop/hadoop-${hadoop_version}/etc/hadoop/hdfs-site.xml
cp ${efs_mount}/conf/core-site.xml ${efs_mount}/hadoop/hadoop-${hadoop_version}/etc/hadoop/core-site.xml
cp ${efs_mount}/conf/cluster.yaml ${efs_mount}/accumulo/accumulo-${accumulo_version}/conf/cluster.yaml
cp ${efs_mount}/conf/accumulo.properties ${efs_mount}/accumulo/accumulo-${accumulo_version}/conf/accumulo.properties
mkdir -p ${efs_mount}/telegraf/conf
cp ${efs_mount}/conf/telegraf.conf ${efs_mount}/telegraf/conf/.
