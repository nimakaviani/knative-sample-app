# Knative App Deployment

Steps below describe deployment of [knative-sample-app](https://github.com/nimakaviani/knative-sample-app) to Knative, deploying from source, blue-green deployment, and achieving HPA for the app. 

**NOTE**: This tutorial has instructions on installing Knative v0.7.1 which
has a hard dependency on K8s 1.14+ due to [#4533](https://github.com/knative/serving/issues/4533).

## 0. Install Istio and Knative

To install Istio on an IBM Kubernetes cluster, run the following command:

```
$ ibmcloud ks cluster-addon-enable istio --cluster <cluster_name_or_ID>
```

For Knative v0.7.1, run `kubectl apply` first with the `--selector` for CRD installation:

```
$  kubectl apply \
   --filename https://github.com/knative/serving/releases/download/v0.7.1/serving-beta-crds.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.7.1/serving-post-1.14.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.7.1/serving.yaml \
   --filename https://github.com/knative/build/releases/download/v0.7.0/build.yaml
```

## 1. Configure Knative with IKS ingress for Knative services

update the istio ingress for the app domain:

`$ kubectl apply -f config/001-knative-ingress.yaml`

get the ingress host name:

`$ ibmcloud ks cluster-get -s --cluster <cluster_name_or_ID> --json | jq -r .ingressHostname`

copy the output value of the above command.

edit the Knative serving domain:

`$ kubectl edit cm/config-domain -n knative-serving` 

and change the cluster domain name from `example.com` to the value you copied from above.


## 2. Deploy your Knative app

deploy the app to Kubernetes:

```bash
kapp deploy -f config/002-app-from-image.yaml -a goapp -p
```

inspect the app status:

```bash
kapp inspect  -t -a 'label:' --filter-name goapp% --column namespace,name,kind,version,conditions,age | grep -v Event
```

get the corresponding service:

```
$ kubectl get ksvc
NAME    URL                                                                       LATESTCREATED   LATESTREADY    READY   REASON
goapp   http://goapp.default.<cluster_name_or_ID>.us-south.containers.appdomain.cloud   goapp-second    goapp-second   True
```

## 3. Get App Info and curl the app

```bash
export APP=$(kubectl get ksvc/goapp -ocustom-columns=D:.status.domain --no-headers)
echo $APP # corresponds to the app url
```

Hit the App endpoint:

```bash
curl $APP
```

## 4. Tweak Autoscaling for the deployed app

```bash
kapp deploy -f config/003-scaled-app-from-image.yaml -a goapp -p
```

notice the annotation below in the new config:

```yaml
metadata:
  annotations:
      autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
      autoscaling.knative.dev/metric: concurrency
      autoscaling.knative.dev/target: "1"
      autoscaling.knative.dev/minScale: "1"
```

curl the endpoint to see the scaling impacts:

```bash
./hack/quick-bench.sh long
```

Notice how the autoscaler kicks in and bumps up the number of app instance

## 5. Deploy canaries

We deploy an updated version of the app:

```bash
kapp deploy -f config/004-traffic-split-app-from-image.yaml -a goapp -p
```

In the new deployment notice the traffic section:

```yaml
traffic:
- tag: current
  revisionName: goapp-first
  percent: 100
- tag: latest
  revisionName: goapp-second
  percent: 0
```

Note that no traffic is redirected to the new version. Lets verify that:

```bash
./hack/quick-bench.sh
```

But the new version can be directly accessed with a dedicated URL:

```bash
curl latest-goapp.default.<cluster_name_or_ID>.us-south.containers.appdomain.cloud
```

In fact, each revision gets its route:

```bash
kubectl get rt -o yaml
```

## 6. Traffic Splitting

We update traffic splitting rules and redeploy:

```bash
kapp deploy -f config/005-release-app-from-image.yaml -a goapp -p
```

In the new deployment notice the change in the traffic section:

```yaml
traffic:
- tag: current
  revisionName: goapp-first
  percent: 50
- tag: candidate
  revisionName: goapp-second
  percent: 50
- tag: latest
  latestRevision: true
  percent: 0
```

Now the traffic is split 50-50. Lets verify that:

```bash
./hack/quick-bench.sh
```

## What next?

There is more to Knative.

Particularly with [Knative Eventing](https://github.com/knative/eventing) and the introduction of [Tekton](https://github.com/tektoncd/pipeline), a new CI/CD project as a spin-off of Knative Build. Go ahead and dig deeper. 
