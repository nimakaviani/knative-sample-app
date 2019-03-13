#! /bin/bash

set -e

if [ -z $REPO ]; then
    if [[ -z ${REPO} ]] && [[ ! -z ${1} ]] ; then
        REPO=$1
    else
        echo "missing repo"
        exit 1
    fi
fi

if [ -z $VERSION ]; then
    if [[ -z ${VERSION} ]] && [[ ! -z ${2} ]] ; then
        VERSION=$2
    else
        echo "missing version: should be v1 or v2"
        exit 1
    fi
fi

docker build -f app/${VERSION}/Dockerfile . -t ${REPO}:${VERSION}
