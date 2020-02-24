---
layout: post
author: tavni
description: This post describes how to import, clone and upload a Virtual Machine disk image to kubernetes cluster.
navbar_active: Blogs
pub-date: October 09
pub-year: 2018
category: news
comments: true
tags: [import, clone, upload, virtual machine, disk image, cdi]
---

# Introduction

Containerized Data Importer (CDI) is a utility to import, upload and clone Virtual Machine images for use with [KubeVirt](https://github.com/kubevirt/kubevirt). At a high level, a persistent volume claim (PVC), which defines VM-suitable storage via a storage class, is created.

A custom controller watches for specific annotation on the persistent volume claim, and when discovered, starts an import, upload or clone process. The status of the each process is reflected in an additional annotation on the associated claim, and when the process completes KubeVirt can create the VM based on the new image.

The Containerized Data Cloner gives the option to clone the imported/uploaded VM image from one PVC to another one either within the same namespace or across two different namespaces.

This Containerized Data Importer project is designed with KubeVirt in mind and provides a declarative method for importing amd uploading VM images into a Kuberenetes cluster. KubeVirt detects when the VM disk image import/upload is complete and uses the same PVC that triggered the import/upload process, to create the VM.

This approach supports two main use-cases:

- A cluster administrator can build an abstract registry of immutable images (referred to as "Golden Images") which can be cloned and later consumed by KubeVirt
- An ad-hoc user (granted access) can import a VM image into their own namespace and feed this image directly to KubeVirt, bypassing the cloning step

For an in depth look at the system and workflow, see the [Design](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/design.md#design) documentation.

# Data Format

The Containerized Data Importer is capable of performing certain functions that streamline its use with KubeVirt. It automatically decompresses gzip and xz files, and un-tar's tar archives. Also, qcow2 images are converted into the raw format which is required by KubeVirt, resulting in the final file being a simple .img file.

Supported file formats are:

- Tar archive
- Gzip compressed file
- XZ compressed file
- Raw image data
- ISO image data
- Qemu qcow2 image data

Note: CDI also supports combinations of these formats such as gzipped tar archives, gzipped raw images, etc.

# Deploying CDI

## Assumptions

- A running Kubernetes cluster that is capable of binding PVCs to dynamically or statically provisioned PVs.
- A storage class and provisioner (only for dynamically provisioned PVs).
- An HTTP file server hosting VM images
- An optional "golden" namespace acting as the image repository. The default namespace is fine for tire kicking.

## Deploy CDI from a release

Deploying the CDI controller is straight forward. In this document the default namespace is used, but in a production setup a [protected namespace](https://github.com/kubevirt/containerized-data-importer#protecting-the-golden-image-namespace) that is inaccessible to regular users should be used instead.

1. Ensure that the cdi-sa service account has proper authority to run privileged containers, typically in a kube environment this is true by default. If you are running an openshift variation of kubernetes you may need to enable privileged containers in the security context:

```bash
$ oc adm policy add-scc-to-user privileged -z cdi-sa
```

2. Deploy the controller from the release manifest:

```bash
$ VERSION=<cdi version>
```

```bash
$ kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-controller.yaml
```

## Deploy CDI using a template

By default when using manifests/generated/cdi-controller.yaml CDI will deploy into the kube-system namespace using default settings. You can customize the deployment by using the generated manifests/generated/cdi-controller.yaml.j2 jinja2 template. This allows you to alter the install namespace, docker image repo, docker image tags, etc. To deploy using the template follow these steps:

1. Install j2cli:

```bash
$ pip install j2cli
```

2. Install CDI:

```bash
$ cdi_namespace=default \
  docker_prefix=kubevirt \
  docker_tag=v1.2.0 \
  pull_policy=IfNotPresent \
  verbosity=1 \
  j2 manifests/generated/cdi-controller.yaml.j2 | kubectl create -f -
```

Check the template file and make sure to supply values for all variables.

Notes:

- The default verbosity level is set to 1 in the controller deployment file, which is minimal logging. If greater details are desired increase the -v number to 2 or 3.
- The importer pod uses the same logging verbosity as the controller. If a different level of logging is required after the controller has been started, the deployment can be edited and applied by using kubectl apply -f <CDI-MANIFEST>. This will not alter the running controller's logging level but will affect importer pods created after the change. To change the running controller's log level requires it to be restarted after the deployment has been edited.

# Download CDI

There are few ways to download CDI through command line:

- git clone command:

```bash
$ git clone https://github.com/kubevirt/containerized-data-importer.git $GOPATH/src/kubevirt.io/containerized-data-importer
```

- download only the yamls:

```bash
$ mkdir cdi-manifests && cd cdi-manifests
$ wget https://raw.githubusercontent.com/kubevirt/containerized-data-importer/kubevirt-centric-readme/manifests/example/golden-pvc.yaml
$ wget https://raw.githubusercontent.com/kubevirt/containerized-data-importer/kubevirt-centric-readme/manifests/example/endpoint-secret.yaml
```

- go get command:

```bash
$ go get kubevirt.io/containerized-data-importer
```

# Start Importing Images

Import disk image is achieved by creating a new PVC with the 'cdi.kubevirt.io/storage.import.endpoint' annotation indicating the url of the source image that we want to download from. Once the controller detects the PVC, it starts a pod which is responsible for importing the image from the given url.

## Create a PVC yaml file named golden-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "golden-pvc"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img" # Required. Format: (http||s3)://www.myUrl.com/path/of/data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # Optional: Set the storage class or omit to accept the default
  # storageClassName: local
```

Edit the PVC above -

- cdi.kubevirt.io/storage.import.endpoint: The full URL to the VM image in the format of: http://www.myUrl.com/path/of/data or s3://bucketName/fileName.
- storageClassName: The default StorageClass will be used if not set. Otherwise, set to a desired StorageClass.

Note: It is possible to use authentication when importing the image from the endpoint url. Please see [using secret during import](https://github.com/kubevirt/containerized-data-importer/blob/master/manifests/example/endpoint-secret.yaml)

## Deploy the manifest yaml files

1. Create the persistent volume claim to trigger the import process:

```bash
$ kubectl -n <NAMESPACE> create -f golden-pvc.yaml
```

2. (Optional) Monitor the cdi-controller:

```bash
$ kubectl -n <CDI-NAMESPACE> logs cdi-deployment-<RANDOM>
```

3. (Optional )Monitor the importer pod:

```bash
$ kubectl -n <NAMESPACE> logs importer-<PVC-NAME> # pvc name is shown in controller log
```

4. Verify the import is completed by checking the following annotation value:

```bash
$ kubectl -n <NAMESPACE> get pvc golden-pvc.yaml -o yaml
```

annotation to verify - cdi.kubevirt.io/storage.pod.phase: Succeeded

# Start cloning disk image

Cloning is achieved by creating a new PVC with the 'k8s.io/CloneRequest' annotation indicating the name of the PVC the image is copied from. Once the controller detects the PVC, it starts two pods (source and target pods) which are responsible for the cloning of the image from one PVC to another using a unix socket that is created on the host itself.

When the cloning is completed, the PVC which the image was copied to, is assigned with the 'k8s.io/CloneOf' annotation to indicate cloning completion. The copied VM image can be used by a new pod only after the cloning process is completed.

The two cloning pods must execute on the same node. Pod adffinity is used to enforce this requirement; however, the cluster also needs to be configured to delay volume binding until pod scheduling has completed.

When using local storage and Kubernetes 1.9 and older, export KUBE_FEATURE_GATES before bringing up the cluster:

```bash
$ export KUBE_FEATURE_GATES="PersistentLocalVolumes=true,VolumeScheduling=true,MountPropagation=true"
```

These features default to true in Kubernetes 1.10 and later and thus do not need to be set.
Regardless of the Kubernetes version, a storage class with volumeBindingMode set to "WaitForFirstConsumer" needs to be created. Eg:

```yaml
kind: StorageClass
   apiVersion: storage.k8s.io/v1
   metadata:
     name: <local-storage-name>
   provisioner: kubernetes.io/no-provisioner
   volumeBindingMode: WaitForFirstConsumer
```

## Create a PVC yaml file named target-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "target-pvc"
  namespace: "target-ns"
  labels:
    app: Host-Assisted-Cloning
  annotations:
    k8s.io/CloneRequest: "source-ns/golden-pvc"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Edit the PVC above -

- k8s.io/CloneRequest: The name of the PVC we copy the image from (including its namespace). For example: "source-ns/golden-pvc".
- add the name of the storage class which defines volumeBindingMode per above. Note, this is not required in Kubernetes 1.10 and later.

## Deploy the manifest yaml files

1. (Optional) Create the namespace where the target PVC will be deployed:

```bash
$ kubectl create ns <TARGET-NAMESPACE>
```

2. Deploy the target PVC:

```bash
$ kubectl -n <TARGET-NAMESPACE> create -f target-pvc.yaml
```

3. (Optional) Monitor the cloning pods:

```bash
$ kubectl -n <SOURCE-NAMESPACE> logs <clone-source-pod-name>
```

```bash
$ kubectl -n <TARGET-NAMESPACE> logs <clone-target-pod-name>
```

4. Check the target PVC for 'k8s.io/CloneOf' annotation:

```bash
$ kubectl -n <TARGET-NAMESPACE> get pvc <target-pvc-name> -o yaml
```

# Start uploading disk image

Uploading a disk image is achieved by creating a new PVC with the 'cdi.kubevirt.io/storage.upload.target' annotation indicating the request for uploading. Part of the uploading process is the authentication of upload requests with an UPLOAD_TOKEN header. The user posts an upload token request to the cluster, and the encrypted Token is returned immediately within the response in the status field. For this to work, a dedicated service is deployed with a nodePort field. At that point, a curl request including the token is sent to start the upload process. Given the upload PVC and the curl request, the controller starts a pod which is responsible for uploading the local image to the PVC.

## Create a PVC yaml file named upload-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: upload-pvc
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.upload.target: ""
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

## Create the upload-token.yaml file

```yaml
apiVersion: upload.cdi.kubevirt.io/v1alpha1
kind: UploadTokenRequest
metadata:
  name: upload-pvc
  namespace: default
spec:
  pvcName: upload-pvc
```

## Upload an image

1. deploy the upload-pvc

```bash
$ kubectl apply -f upload-pvc.yaml
```

2. Request for upload token

```bash
$ TOKEN=$(kubectl apply -f upload-token.yaml -o="jsonpath={.status.token}")
```

3. Upload the image

```bash
$ curl -v --insecure -H "Authorization: Bearer $TOKEN" --data-binary @tests/images/cirros-qcow2.img https://$(minikube ip):31001/v1alpha1/upload
```

# Security Configurations

## RBAC Roles

CDI runs under a custom ServiceAccount (cdi-sa) and uses the [Kubernetes RBAC model](https://v1-13.docs.kubernetes.io/docs/reference/access-authn-authz/rbac/) to apply an application specific custom ClusterRole with rules to properly access needed resources such as PersistentVolumeClaims and Pods.

## Protecting VM Image Namespaces

Currently there is no support for automatically implementing [Kubernetes ResourceQuotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/) and Limits on desired namespaces and resources, therefore administrators need to manually lock down all new namespaces from being able to use the StorageClass associated with CDI/KubeVirt and cloning capabilities. This capability of automatically restricting resources is planned for future releases. Below are some examples of how one might achieve this level of resource protection:

- Lock Down StorageClass Usage for Namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: protect-mynamespace
spec:
  hard:
    <STORAGE-CLASS-NAME>.storageclass.storage.k8s.io/requests.storage: "0"
```

> note "Note"
> `.storageclass.storage.k8s.io/persistentvolumeclaims: "0"` would also accomplish the same affect by not allowing any pvc requests against the storageclass for this namespace.

- Open Up StorageClass Usage for Namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: protect-mynamespace
spec:
  hard:
    <STORAGE-CLASS-NAME>.storageclass.storage.k8s.io/requests.storage: "500Gi"
```

> note "Note"
> `.storageclass.storage.k8s.io/persistentvolumeclaims: "4"` could be used and this would only allow for 4 pvc requests in this namespace, anything over that would be denied.
