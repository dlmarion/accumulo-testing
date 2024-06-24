# CollectD-Timely-Grafana Stack

This Docker image is designed to communicate with a locally running Apache Accumulo
instance for Grafana dashboard development purposes. This Docker image contains
CollectD, Timely, and Grafana configured such that CollectD is listening on port
8125 for StatsD messages that are forwarded to Timely which are then stored in
Accumulo. Grafana is available on port 3000 and it will query Timely for timeseries
metrics thar are stored in tables in Accumulo.


## Deployment

1. Run `build-image.sh`, after this runs the timely jar files will be copied out
   of the Docker image and put into the `build_output` directory.
2. Copy the timely jar files from the `build_output` directory to `$ACCUMULO_HOME/lib`
3. Add the following to `accumulo.properties':
```
general.micrometer.enabled=true
general.micrometer.jvm.metrics.enabled=true
general.micrometer.factory=org.apache.accumulo.test.metrics.TestStatsDRegistryFactory
```
4. Add the following to the `JAVA_OPTS` variable in `accumulo-env.sh`:
```
  "-Dtest.meter.registry.host=localhost"
  "-Dtest.meter.registry.port=8125"
```
5. Start ZooKeeper, Hadoop, and Accumulo
6. Execute `run-container.sh` to start CollectD, Timely, and Grafana

