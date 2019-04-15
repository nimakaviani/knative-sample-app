#! /bin/bash

set -ex

echo "Create the app"
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: goapp
  namespace: default
spec:
  runLatest:
    configuration:
      revisionTemplate:
        metadata:
          annotations:
            autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
            autoscaling.knative.dev/metric: concurrency
            autoscaling.knative.dev/target: "2"
            autoscaling.knative.dev/minScale: "1"
        spec:
          container:
            image: nimak/knative-sample-app:v3
            imagePullPolicy: Always
            env:
              - name: NAME
                value: "John"
EOF

sleep 5

export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.domain --no-headers)

echo "Wait for it to be ready"
while ! curl -sf $APP ; do sleep 1 ; done

echo "hit the autoscaler with burst of requests"
for i in `seq 7`; do
    curl -s "$APP?wait=10s" 1>/dev/null &
done

echo "wait for the autoscaler to kick in and the bursty requests to finish"
sleep 30

echo "send longer requets"
for i in `seq 5`; do
    curl "$APP?wait=1m"&
    sleep 1;
done

