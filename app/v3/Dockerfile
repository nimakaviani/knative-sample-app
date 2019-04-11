from golang:1.12.2-stretch as builder
workdir /go/src/github.com/nimakaviani/knative-sample-app
copy . .
run go build -o out/server github.com/nimakaviani/knative-sample-app/app/v3/

from ubuntu:bionic
copy --from=builder /go/src/github.com/nimakaviani/knative-sample-app/out/server /server
cmd ["/server"]
