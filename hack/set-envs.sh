#! /bin/bash

set -ex

# may need to be updated depending on how many loadBalancers are configured
export INGRESSIP=$(kubectl get svc istio-ingressgateway -n istio-system -ocustom-columns=D:.status.loadBalancer.ingress[0].ip --no-headers)
export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.url --no-headers)
