#! /bin/bash

## Start Timely
/opt/timely/bin/start-all.sh

# Start CollectD
export LD_PRELOAD=/usr/lib/jvm/java-11-openjdk/lib/server/libjvm.so
/usr/sbin/collectd

# Start Grafana
GRAFANA_USER=grafana 
GRAFANA_GROUP=grafana
GRAFANA_HOME=/usr/share/grafana
LOG_DIR=/var/log/grafana
DATA_DIR=/var/lib/grafana
MAX_OPEN_FILES=10000
CONF_DIR=/etc/grafana
CONF_FILE=/etc/grafana/grafana.ini
RESTART_ON_UPGRADE=true
PLUGINS_DIR=/var/lib/grafana/plugins
PROVISIONING_CFG_DIR=/etc/grafana/provisioning
PID_FILE_DIR=/var/run/grafana

/usr/sbin/grafana-server --homepath=/usr/share/grafana --config=${CONF_FILE} \
                            --pidfile=${PID_FILE_DIR}/grafana-server.pid --packaging=rpm cfg:default.paths.logs=${LOG_DIR} \
                            cfg:default.paths.data=${DATA_DIR} cfg:default.paths.plugins=${PLUGINS_DIR} \
                            cfg:default.paths.provisioning=${PROVISIONING_CFG_DIR}

