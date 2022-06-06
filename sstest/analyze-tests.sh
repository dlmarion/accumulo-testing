#!/bin/bash

for dir in "tests/"*
do
	echo "$dir | $(grep BUSY $dir/ssquery-single-logs.txt | wc -l) | $(grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[:]9996" $dir/ssquery-single-logs.txt | sort -u | wc -l) | $(wc -l $dir/ssquery-all-logs.txt) | $(egrep -o "initialServers.*" $dir/query-job.yaml) | $(egrep -o "initialBusyTimeout.*" $dir/query-job.yaml) | $(egrep -o "threads.*" $dir/query-job.yaml) | $(grep grep $dir/query-job.yaml) | $(egrep -o 'eventual|immediate' $dir/query-single.yaml) | $(egrep -o "FINAL.*" $dir/ssquery-single-logs.txt)"
done
