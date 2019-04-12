#! /bin/bash

set -ex

echo "hit the autoscaler with burst of requests"
for i in `seq 7`; do
    curl -s "goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?wait=10s" 1>/dev/null &
done

echo "wait for the autoscaler to kick in and the bursty requests to finish"
sleep 30

echo "send longer requets"
for i in `seq 5`; do
    curl "goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?wait=1m"&
    sleep 1;
done
