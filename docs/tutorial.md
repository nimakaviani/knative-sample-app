# Knative App Deployment

Steps below describe deployment of [knative-sample-app](https://github.com/nimakaviani/knative-sample-app) to Knative, deploying from source, blue-green deployment, and achieving HPA for the app. 

## 0. Install Knative

for Knative v0.3.0
```
$ kubectl apply --filename https://github.com/knative/serving/releases/download/v0.3.0/serving.yaml \
--filename https://github.com/knative/build/releases/download/v0.3.0/release.yaml \
--filename https://github.com/knative/eventing/releases/download/v0.3.0/release.yaml \
--filename https://github.com/knative/eventing-sources/releases/download/v0.3.0/release.yaml 
```

for Knative v0.4.0
```
$ kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/serving.yaml \
--filename https://github.com/knative/build/releases/download/v0.4.0/build.yaml \
--filename https://github.com/knative/eventing/releases/download/v0.4.0/release.yaml \
--filename https://github.com/knative/eventing-sources/releases/download/v0.4.0/release.yaml \
--filename https://raw.githubusercontent.com/knative/serving/v0.4.0/third_party/config/build/clusterrole.yaml
```

## 1. Configure Knative with IKS ingress for Knative services

update the istio ingress for the app domain:

`$ kapp deploy -a goapp -f config/001-knative-ingress.yaml`

get the ingress host name:

`$ ibmcloud ks cluster-get -s --cluster nk3-eirini-cluster --json | jq -r .ingressHostname`

copy the output value of the above command.

edit the Knative serving domain:

`$ kubectl edit cm/config-domain -n knative-serving` 

and change the cluster domain name from `example.com` to the value you copied from above.


## 2. Deploy your Knative app

deploy the app to Kubernetes:

`$ kapp deploy -f config/002-app-from-image.yaml -a goapp -p`

inspect the app status:

`$ kapp inspect  -t -a 'label:' --filter-name goapp% --column namespace,name,kind,version,conditions,age | grep -v Event`

get the corresponding revision for the deployed configuration:

```
$ kubectl get revisions
NAME          SERVICE NAME          AGE   READY   REASON 
goapp-wtkkg   goapp-wtkkg-service   17m   True
```

## 3. Update the routes file

copy the name of the revision and update `004-route-input.yaml`:

```yaml
#@data/values
---
revisions:
  - name: goapp-wtkkg # validation for whatever
    percent: 100 # some percent
```

## 4. Apply routes to Knative

template and update the route to make the app available on the web:

```
$ ytt tpl -f config/004-route-input.yaml -f config/004-app-route.yaml | kapp deploy -a goapp -p -y  -f -
```

curl the app endpoint:

```
$ curl goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud
```

the deployed app version should respond.

## 5. Deploy build templates to build from source

install the kaniko build template:

```
$ kapp deploy -a goapp -p -f https://raw.githubusercontent.com/knative/build-templates/master/kaniko/kaniko.yaml
```

update `005-creds-input.yaml` and supply the secrets for dockerhub and github to your Knative app:

```
$ ytt tpl -f config/005-creds-input.yaml -f config/005-kaniko-build-account.yaml | kapp deploy -a goapp -y -p -f - 
```

## 6. Deploy new version from source and update routes

deploy the new version of your app and make it get built from source:

```
$ kapp deploy -p -f config/006-app-from-source.yaml -a goapp
```

get the revisions and update the route input:

```
$ kubectl get revisions
NAME          SERVICE NAME          AGE   READY   REASON
goapp-2cmgc   goapp-2cmgc-service   8m    True
goapp-hgmmz   goapp-hgmmz-service   19m   True
```

with a 80/20 split between the old and the new versions, `004-route-input.yaml` would be like the following:

```yaml
#@data/values
---
revisions:
  - name: goapp-hgmmz 
    percent: 80 
  - name: goapp-2cmgc
    percent: 20
```

and we proceed to update the route:

```
$ ytt tpl -f config/004-route-input.yaml -f config/004-app-route.yaml | kapp deploy -a goapp -p -y  -f -
```

curl the app endpoint and notice that with a ~20% ratio we hit the new endpoint:

```
$ curl goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud
```

## 7. Deploy to production and tweak auto-scaling

assuming the last build was successful, let's move it to production.

deploy the new version from the latest app image (the one we created in the previous step):

```
$ kapp deploy -a goapp -p -f config/007-app-from-updated-image.yaml
```

notice the annotation below in the new config:

```yaml
metadata:
  annotations:
    autoscaling.knative.dev/class: kpa.autoscaling.knative.dev
    autoscaling.knative.dev/minScale: "2"
```

update revisions for the new route to be created:

```
$ kubectl get revisions
NAME          SERVICE NAME          AGE   READY   REASON
goapp-2cmgc   goapp-2cmgc-service   8m    True
goapp-gqsfz   goapp-gqsfz-service   41s   True
goapp-hgmmz   goapp-hgmmz-service   19m   True
```

change the way traffic is directed:

```yaml
#@data/values
---
revisions:
  - name: goapp-hgmmz 
    percent: 10 
  - name: goapp-2cmgc
    percent: 0
 - name: goapp-gqsf
    percent: 90
```

and proceed to update the route:

```
$ ytt tpl -f config/004-route-input.yaml -f config/004-app-route.yaml | kapp deploy -a goapp -p -y  -f -
```

curl the app endpoint and notice that our requests get load balanced across the two pods:

```
$ curl goapp.default.nk3-eirini-cluster.us-south.containers.appdomain.cloud
```

## What next?

There is more to Knative.

Particularly with [Knative Eventing](https://github.com/knative/eventing) and the introduction of [Tekton](https://github.com/tektoncd/pipeline), a new CI/CD project as a spin-off of Knative Build. Go ahead and dig deeper. 

