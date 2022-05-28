#!/bin/bash

echo "start scan counts"
echo
kubectl logs $1 | grep "Starting scan" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[:][0-9]+" | sort | uniq -c

echo
echo "continue scan counts"
echo 

kubectl logs $1 | grep "Continuing scan" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[:][0-9]+" | sort | uniq -c

echo
echo "Connection stats"
echo

kubectl logs $1 | grep -o "ThriftTransportPool.*" | grep -v Returned  | sort | uniq -c
kubectl logs $1 | grep -o "Returned.*ioCount" | sort | uniq -c

echo
echo "Scan server to tablet stats"
echo

kubectl logs $1 | grep -o "For tablet.*chose.*" | sort | uniq -c

echo
echo "Busy counts"
echo 

kubectl logs $1 | grep BUSY | wc

echo
echo "FINAL STATS"
echo

kubectl logs --tail=10 $1 | grep FINAL
