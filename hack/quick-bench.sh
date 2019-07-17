#! /bin/bash

set -e

# may need to be updated depending on how many loadBalancers are configured
export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)

export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.domain --no-headers)

if ! [ -z $1 ] && [ $1 == "long" ]; then

    set -x

    echo "send longer requets"
    for i in `seq 10`; do
        curl -H "Host: $APP" "http://$INGRESSIP?wait=5s"&
        sleep 1;
    done
else
    echo "send short requets"
    for i in `seq 10`; do
        curl -H "Host: $APP" "http://$INGRESSIP"
    done
fi
