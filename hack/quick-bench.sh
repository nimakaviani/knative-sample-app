#! /bin/bash

set -e

# may need to be updated depending on how many loadBalancers are configured
export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.url --no-headers)
echo $APP

if ! [ -z $1 ] && [ $1 == "long" ]; then

    set -x

    echo "send longer requets"
    for i in `seq 10`; do
        curl "$APP?wait=5s"&
        sleep 1;
    done
else
    echo "send short requets"
    for i in `seq 10`; do
        curl "$APP"
    done
fi
