#!/bin/sh

set -e

go fmt github.com/nimakaviani/knative-sample-app/...

# export GOOS=linux GOARCH=amd64

go build -o out/server github.com/nimakaviani/knative-sample-app/app/${1}
