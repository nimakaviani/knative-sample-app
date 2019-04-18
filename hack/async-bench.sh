#! /bin/bash

set -ex

echo "> create the app"
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
          allowAsync: true
          timeoutSeconds: 1000
          container:
            image: nimak/knative-sample-app:v3
            imagePullPolicy: Always
            env:
              - name: NAME
                value: "John"
EOF

if ! [ -z $1 ] && [ $1 == "launch" ]; then
    sleep 15
fi

# may need to be updated depending on how many loadBalancers are configured
export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)

export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.domain --no-headers)

echo "> Wait for it to be ready"
while ! curl -sf -H "Host: $APP" "http://$INGRESSIP" 1>/dev/null ; do
    sleep 1 ;
done

if ! [ -z $1 ] && [ $1 == "launch" ]; then

    echo "> delete old references"
    rm -f guid.txt

    echo "> hit the autoscaler with burst of requests"
    for i in `seq 7`; do
        curl -s -H "Host: $APP" "http://$INGRESSIP?wait=10s" 1>/dev/null&
    done

    sleep 15

    echo "> launch async requests"
    for i in $(seq 5); do
        sleep 1
        curl -s -H "Async: true" -H "Host: $APP" "http://$INGRESSIP?wait=15m&check=$i" >> guid.txt
        echo >> guid.txt
    done
else
    echo "> query: "
    cat guid.txt | awk '{print $1}' | xargs -n1 -I {} sh -c 'echo {}; curl -H "Async: true" -H "Async-UUID: {}" -H "Host: $APP" "http://$INGRESSIP"; echo'
fi
