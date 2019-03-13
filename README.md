# Sample Docker App for Knative

## Requirements

For the deployment and inspection of the Knative application discussed here, we are using the following tools:

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/): The Kubernetes command-line tool for interacting with a Kubernetes deployment.
- [ytt - YAML Templating Tool](https://get-ytt.io) is the structure aware templating tool that [@cppforlife](https://github.com/cppforlife) and I developed for better templating of YAML configuration.
- [kapp - Kubernetes Application Manager](https://get-kapp.io) is the Kubernetes workflow management tool released by [@cppforlife](https://github.com/cppforlife) that consumes the generated output from `ytt`.
- [IBM Kubernetes Service (IKS)](https://www.ibm.com/cloud/container-service): the demo uses a Kubernetes cluster on IBM Cloud to launch and run the sample application. Some of the adjustments to the deployment process are specific to IKS.

The combination of `ytt` and `kapp` can be an alternative to a HELM chart+workflow management. While this project is pretty small for the purpose of the tool, it can be a good starting point.

## Build the app

### Build locally:

Run the following:

```bash
$ VERSION=<app-version> # this should be v1 or v2
$ ./hack/build.sh $VERSION 
```

### Build the Docker image to push to a registry:

The `Dockerfile` builds the go app and puts it in the local registry. You can then upload it to dockerhub or your registry of choice.

```bash
$ REPO=<your-docker-registry>
$ VERSION=<app-version> # this should be v1 or v2
$ ./hack/dockerize.sh ${REPO} ${VERSION}
$ docker push ${REPO}:${VERSION}
```

## Sample app + Knative

This application is meant to serve as a sample to demonstrate how Knative can be used as a serverless platform, how to apply revisions to a Knative serverless app, and how to achieve blue-green deployment and HPA. For the details of going through the tutorial, follow [this tutorial document](docs/tutorial.md).

