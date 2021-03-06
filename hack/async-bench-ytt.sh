#! /bin/bash

set -ex

WAIT_TIME="${2:-4m}"

echo "> create the app"
ytt tpl -f config/db-input.yaml -f config/010-app-from-image.yaml | kubectl apply -f -

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
        curl -s -H "Async: true" -H "Host: $APP" "http://$INGRESSIP?wait=$WAIT_TIME&check=$i" >> guid.txt
        echo >> guid.txt
    done
else
    echo "> query: "
    cat guid.txt | awk '{print $1}' | xargs -n1 -I {} sh -c 'echo "> {}"; curl -H "Async: true" -H "Async-UUID: {}" -H "Host: $APP" "http://$INGRESSIP"; echo'
fi
