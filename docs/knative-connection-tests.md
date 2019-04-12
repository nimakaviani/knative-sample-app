# Knative Connection Testing

This documents describes steps for reproducing the behavior in Knative where in-flight connections are dropped as a result of Pod scale down.


## Install & Run Tests

install:

```
kubectl apply -f https://raw.githubusercontent.com/nimakaviani/knative-sample-app/master/config/010-app-from-image.yaml
```

watch pods:

```
kubectl get pods
```

run tests:

```
./hack/bench.sh
```

observe that once pods are killed, eventually the gateway responds with `504`

```
<html>
  <head><title>504 Gateway Time-out</title></head>
  <body bgcolor="white">
    <center><h1>504 Gateway Time-out</h1></center>
    <hr><center>nginx</center>
  </body>
</html>

```
