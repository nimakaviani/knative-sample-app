# Performance Testing Async Knative Calls

This document describes how to test autoscaling for Async calls in Knative based on the PoC implementation at [github.com/nimakaviani/serving](https://github.com/nimakaviani/serving).

## Deploy Application

build docker image and push `v3` to your repo like below:

```
./hack/dockerize.sh nimak/knative-sample-app v3
docker push nimak/knative-sample-app:v3
```

deploy the application (delete previous version if it exists):

```
kapp delete -a async-app -y && kapp deploy -f config/010-app-from-image.yaml -a async-app -p -y
```

curl the app with a given prime number to make sure it runs:

```
curl "goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337&check=done"
```

if done right, the app should indicate whether the number is prime or not. Not `true` at the end of the line:

```
Hi there Nima!!
Check: done
IsPrime: true
```

## Monitor queueing stats reports

get on the user container:

```
kubectl exec -it -c user-container [pod-name] bash
```

run the following command:

```
watch -n0.1 "curl -s localhost:9090/metrics | grep -v '#'"
```

the output would show stats results reported by the queue.

## Load test the Application

run a `for` loop like the following and notice that the auto-scaler bump the number of app instances

```
for i in $(seq 20); do sleep 1; curl "goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337&check=$i"& done
```

this should trigger the autoscaler to launch one or more new containers after a few requests.

## Try the Application in Async mode

run the command above with `Async` enabled

```
for i in $(seq 20); do sleep 1; curl -H "Async: true" "goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud?num=1000012337&check=$i" >> guid.txt; echo >> guid.txt& done
```

curl the endpoint with guids:

```
cat guid.txt | xargs -n1 -I {} sh -c 'echo {}; curl -H "Async: true" -H "Async-UUID: {}"  goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud; echo'
```

## End-to-End with a Single Script:

Provide connection string for a postgres database in [hack/async-bench-all.sh](hack/async-bench-all.sh#L27)

Then run the following:

```bash
# launch the requests with a 3m delay for async
./hack/async-bench-all.sh launch 3m

# inspect the async request guids and pods they are running on:
# first column is the request guid and second column is the pod id
cat guid.txt

# wait for the requests to finish and then query for results 
./hack/async-bench-all.sh

```
