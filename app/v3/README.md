# Performance Testing Async Knative Calls

This document describes how to enable Async calls for Knative based on the PoC implementation [github.com/nimakaviani/serving](https://github.com/nimakaviani/serving). 

## Deploy Application

build docker image an push `v3` to your repo like below:

```
./hack/dockerize.sh nimak/knative-sample-app v3
docker push nimak/knative-sample-app:v3
```

deploy the application:

```
kapp deploy -y -a async-app -p -f config/010-app-from-image.yaml
```

curl the app with a given prime number to make sure it runs:

```
curl goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337
```

if done right, the app should indicate whether the number is prime or not. Not `true` at the end of the line:

```
Hi there Nima!! -  - true
```

## Load test the Application

run a `for` loop like the following and notice that the auto-scaler bumps the number of app instances

```
for i in $(seq 20); do sleep 1; curl   goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337& done
```

this should trigger the autoscaler to launch one or more new container after a few requests.

## Load test the Application in Async mode

run the command above with `Async` enabled

```
for i in $(seq 20); do sleep 1; curl -H "Async: true" goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337 >> guid.txt; echo >> guid.txt& done
```

curl the endpoint with guids:

```
cat guid.txt | xargs -n1 -I {} curl -H "Async: true" -H "Async-UUID: {}"  goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud
```
