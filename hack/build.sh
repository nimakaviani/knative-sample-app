#!/bin/sh

set -e

if [ -z $VERSION ]; then
    if [[ -z ${VERSION} ]] && [[ ! -z ${1} ]] ; then
        VERSION=$1
    else
        echo "missing version: should be v1 or v2"
        exit 1
    fi
fi

go fmt github.com/nimakaviani/knative-sample-app/...

# export GOOS=linux GOARCH=amd64

go build -o out/server github.com/nimakaviani/knative-sample-app/app/${VERSION}
