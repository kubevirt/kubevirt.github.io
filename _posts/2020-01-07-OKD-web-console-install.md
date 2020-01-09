---
layout: post
author: Alberto Losada Grande
description: This article focuses on running the OKD web console in a native Kubernetes cluster leveraging the deep integrations with KubeVirt. OKD web console will allow us to create, manage and delete virtual machines from a friendly user interface
navbar_active: Blogs
category: news
comments: true
title: Managing KubeVirt with Openshift Web Console
pub-date: January 7
pub-year: 2020
---

In the previous post [KubeVirt user interface options](https://kubevirt.io/2019/KubeVirt_UI_options.html) we described and showed some features, pros and cons of using OKD console to manage our KubeVirt deployment. This blog post will focus on installing and running the OKD web console in our Kubernetes cluster so that we can leverage the deep integrations between KubeVirt and the OKD web console.

There are two options to run the OKD web console to manage our Kubernetes cluster. Click on any of those so you can go directly to the proper procedure you choose.

- [Executing the web console as a binary.](#binary-installation) This way is the only one described in the [OKD web console repository](https://github.com/openshift/console#build-everything), so looks like the official procedure when running in [native Kubernetes](https://github.com/openshift/console#native-kubernetes).
- [Executing the web console as another pod](#containerized-installation). The idea is to leverage the containerized version available as origin-console in the public [openshift image repository](https://quay.io/repository/openshift/origin-console?tag=latest&tab=tags)


## What is the OKD web console

> The [OKD web console](https://github.com/openshift/console) is a user interface accessible from a web browser. Developers can use the web console to visualize, browse, and manage the contents of namespaces. It is also referred as a more friendly kubectl in the form of a single page webapp. It integrates with other services like monitoring, chargeback, and OLM. Some things that go on behind the scenes include:

- Proxying the Kubernetes API under /api/kubernetes
- Providing additional non-Kubernetes APIs for interacting with the cluster
- Serving all frontend static assets
- User Authentication

As it is stated in the official GitHub's repository, the OKD web console runs as a binary listening in local port tcp/9000. The static assets required to run the web console are served by the binary itself. Administrators can also customize the web console using extensions, which let you run scripts and load custom stylesheets when the web console loads.

When you access the web console from a browser, it first loads all required static assets. It then makes requests to the Kubernetes APIs using the values defined as environment variables in the host that is running. Actually, there is a script called environment.sh that helps to export the correct values for these environment variables.  

The web console uses WebSockets to maintain a persistent connection with the API server and receive updated information as soon as it is available. Note as well that JavaScript must be enabled to use the web console. For the best experience,use a web browser that supports WebSockets. OKD web console's developers details Google Chrome/Chromium version 76 or greater as a dependency used in their integration tests.

Unlike what is explained in the [official repository](https://github.com/openshift/console#native-kubernetes), OKD actually executes the OKD web console in a pod placed in master nodes. Therefore, even not mentioned, we are going to show how to run the OKD web console as a pod in our Kubernetes cluster instead of running it as a local binary.


## Binary installation

`This installation is suggested to be a development installation, since it is mainly used by the OKD web console developers to test new features.`

In this section we are going to compile the OKD web console from the source code and execute it as a binary artifact in a CentOS 8 server which does not belong to our Kubernetes cluster. The following diagram shows the relation between all the components and interactions: user, OKD web console and Kubernetes cluster.

<img src="/assets/2020-01-07-OKD-web-console-install/OKD-console-kubevirt.png" alt="Lab diagram">

Note that, it is possible to run the OKD web console on a Kubernetes master, node or as shown in a server outside the cluster with access to the cluster API. In this last case, the external server can be configured with different security and network settings or even different hardware resources.

First step in our binary installation is cloning the [repository](https://github.com/openshift/console). 

### Dependencies

Below are detailed the dependencies needed to compile the OKD web console artifact:

- **Operating System**. We have chosen CentOS 8 as our operating system for the server running the binary OKD web console. Kubernetes cluster is running latest CentOS 7.

```sh
$ cat /etc/redhat-release 
CentOS Linux release 8.0.1905 (Core)
```

- **Kubernetes**. In our case we have deployed the latest available version at the moment of writing V1.17. Kubernetes cluster comprised by one master node and one worker node with enough CPU (4vCPUs) and memory (16Gi) to run KubeVirt and a couple of KubeVirt's VirtualMachineInstances. No extra storage apart from the operating system filesystem was needed since the VirtualMachines will run as container-disk instances.

```sh
$ kubectl get nodes -o wide
NAME                            STATUS   ROLES    AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME
blog-master-00.kubevirt.local   Ready    master   29h   v1.17.0   192.168.123.250   <none>        CentOS Linux 7 (Core)   3.10.0-957.27.2.el7.x86_64   docker://1.13.1
blog-worker-00.kubevirt.local   Ready    <none>   29h   v1.17.0   192.168.123.232   <none>        CentOS Linux 7 (Core)   3.10.0-957.27.2.el7.x86_64   docker://1.13.1
```

- **node.js >= 8**

We are going to install nodejs 10, available as an AppStream module:

```sh
$ sudo yum module install nodejs
Installed:
  nodejs-1:10.16.3-2.module_el8.0.0+186+542b25fc.x86_64   npm-1:6.9.0-1.10.16.3.2.module_el8.0.0+186+542b25fc.x86_64  

Complete!
```

- **yarn >= 1.3.2**

Yarn is a dependency of node.js. In this case, we need to add the official yarn.repo to our configured local repositories.

```sh
$ sudo curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
$ sudo rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
$ sudo yum install yarn

$ yarn --version
1.21.1
```

- **go >= 1.11+**

Golang is available as an AppStream module in CentOS 8:

```sh
$ sudo yum module install go-toolset

Installed:
  golang-1.11.6-1.module_el8.0.0+192+8b12aa21.x86_64
                    
```

- **jq (for contrib/environment.sh)**

Finally install jq in order to work with JSON data.

```sh
$ yum install jq

Installed:
  jq.x86_64 0:1.5-1.el7
```                                                                                                                     


### Compiling OKD web console

Once all dependencies are met, basically we need get into the cloned directory and export the correct variables that will be used during the building process. Once done, just run the build.sh script which actually calls the build-frontend and build-backend scripts. 

```sh
$ git clone https://github.com/openshift/console.git
$ cd console/
$ export KUBECONFIG=~/.kube/config
$ source ./contrib/environment.sh
Using https://192.168.123.250:6443

$ ./build.sh 
...
Done in 215.91s.
```

Finally the result is a binary file called bridge inside the bin folder. Prior to run the "bridge" verify that the port where the OKD web console expecting connections (9000/tcp) is not blocked.

```sh
$ iptables -A INPUT -p tcp --dport 9000 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
```

Then, now execute the artifact:

```sh
$ ./bin/bridge 
2020/01/7 10:21:17 cmd/main: cookies are not secure because base-address is not https!
2020/01/7 10:21:17 cmd/main: running with AUTHENTICATION DISABLED!
2020/01/7 10:21:17 cmd/main: Binding to 0.0.0.0:9000...
2020/01/7 10:21:17 cmd/main: not using TLS
```

At this point you must be able to connect to the OKD web console from your network. Note that by default there is no authentication required to login into the console and the connection is using HTTP protocol. There are variables in the environment.sh that can change this default behaviour. In our case the default configuration is valid to show how to integrate the web console to run and manage our KubeVirt resources.

Probably, you will face the following issue once you see the webUI: "services is forbidden: User "system:serviceaccount:kube-system:default" cannot list resource "services" in API group "" in the namespace default"

<img src="/assets/2020-01-07-OKD-web-console-install/okd-serviceaccount-error.png" alt="OKD sa error" width="1110" height="720">

The problem is that the "default" service account does not have enough privileges to show all the cluster objects. Therefore it is lacking cluster-admin privileges. Instead of adding cluster-admin privileges to a default service account that can be used by any application running in the kube-system namespace, we are going to create a new service account. This service account will be used by the OKD web console to connect to our Kubernetes cluster and will be assigned the proper permissions:

```sh
$ kubectl create sa console -n kube-system
$ kubectl create clusterrolebinding console --clusterrole=cluster-admin --serviceaccount=kube-system:console -n kube-system
```

Once created, modify the environment.sh and change the line that begins with secretname as show below:

```sh
vim contrib/environment.sh 
secretname=$(kubectl get serviceaccount **console** --namespace=kube-system -o jsonpath='{.secrets[0].name}')
``` 

Once done, export again the variables configured in the environment.sh file and reload your connection to the console.

```sh
$ source ./contrib/environment.sh
```

## Deploy KubeVirt using the Hyperconverged Cluster Operator (HCO)

In order to ease the installation of KubeVirt we are going to deploy it using a unified operator called **[HCO](https://github.com/kubevirt/hyperconverged-cluster-operator)**. The goal of the hyperconverged-cluster-operator (HCO) is to provide a single entrypoint for multiple operators - [kubevirt](https://blog.openshift.com/a-first-look-at-kubevirt/), [cdi](http://kubevirt.io/2018/CDI-DataVolumes.html), [networking](https://github.com/kubevirt/cluster-network-addons-operator/blob/master/README.md), etc... - where users can deploy and configure them in a single object. This operator is sometimes referred to as a "meta operator" or an "operator for operators". Most importantly, this operator doesn't replace or interfere with OLM. It only creates operator CRs, which is the user's prerogative. More information about HCO can be found in the post published by Ryan Hallisey: [Hyper Converged Operator on OCP 4 and K8s(HCO)](https://kubevirt.io/2019/Hyper-Converged-Operator.html) in this blog.

The HCO repository provides plenty of information on how to install the operator. We have installed as [Using the HCO without OLM or Marketplace] (https://github.com/kubevirt/hyperconverged-cluster-operator#using-the-hco-without-olm-or-marketplace). Basically calling this deployment script as cluster-admin:

```sh
$ curl https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/deploy.sh | bash
+ kubectl create ns kubevirt-hyperconverged
namespace/kubevirt-hyperconverged created
+ namespaces=("openshift")
+ for namespace in ${namespaces[@]}
++ kubectl get ns openshift
Error from server (NotFound): namespaces "openshift" not found
+ [[ '' == '' ]]
+ kubectl create ns openshift
namespace/openshift created
++ kubectl config current-context
+ kubectl config set-context kubernetes-admin@kubernetes --namespace=kubevirt-hyperconverged
Context "kubernetes-admin@kubernetes" modified.
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/cluster-network-addons00.crd.yaml
customresourcedefinition.apiextensions.k8s.io/networkaddonsconfigs.networkaddonsoperator.network.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/containerized-data-importer00.crd.yaml
customresourcedefinition.apiextensions.k8s.io/cdis.cdi.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/hco.crd.yaml
customresourcedefinition.apiextensions.k8s.io/hyperconvergeds.hco.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/kubevirt00.crd.yaml
customresourcedefinition.apiextensions.k8s.io/kubevirts.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/node-maintenance00.crd.yaml
customresourcedefinition.apiextensions.k8s.io/nodemaintenances.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/scheduling-scale-performance00.crd.yaml
customresourcedefinition.apiextensions.k8s.io/kubevirtcommontemplatesbundles.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/scheduling-scale-performance01.crd.yaml
customresourcedefinition.apiextensions.k8s.io/kubevirtmetricsaggregations.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/scheduling-scale-performance02.crd.yaml
customresourcedefinition.apiextensions.k8s.io/kubevirtnodelabellerbundles.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/scheduling-scale-performance03.crd.yaml
customresourcedefinition.apiextensions.k8s.io/kubevirttemplatevalidators.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/crds/v2vvmware.crd.yaml
customresourcedefinition.apiextensions.k8s.io/v2vvmwares.kubevirt.io created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/cluster_role.yaml
role.rbac.authorization.k8s.io/cluster-network-addons-operator created
clusterrole.rbac.authorization.k8s.io/hyperconverged-cluster-operator created
clusterrole.rbac.authorization.k8s.io/cluster-network-addons-operator created
clusterrole.rbac.authorization.k8s.io/kubevirt-operator created
clusterrole.rbac.authorization.k8s.io/kubevirt-ssp-operator created
clusterrole.rbac.authorization.k8s.io/cdi-operator created
clusterrole.rbac.authorization.k8s.io/node-maintenance-operator created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/service_account.yaml
serviceaccount/cdi-operator created
serviceaccount/cluster-network-addons-operator created
serviceaccount/hyperconverged-cluster-operator created
serviceaccount/kubevirt-operator created
serviceaccount/kubevirt-ssp-operator created
serviceaccount/node-maintenance-operator created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/cluster_role_binding.yaml
rolebinding.rbac.authorization.k8s.io/cluster-network-addons-operator created
clusterrolebinding.rbac.authorization.k8s.io/hyperconverged-cluster-operator created
clusterrolebinding.rbac.authorization.k8s.io/cluster-network-addons-operator created
clusterrolebinding.rbac.authorization.k8s.io/kubevirt-operator created
clusterrolebinding.rbac.authorization.k8s.io/kubevirt-ssp-operator created
clusterrolebinding.rbac.authorization.k8s.io/cdi-operator created
clusterrolebinding.rbac.authorization.k8s.io/node-maintenance-operator created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/operator.yaml
deployment.apps/hyperconverged-cluster-operator created
deployment.apps/cluster-network-addons-operator created
deployment.apps/virt-operator created
deployment.apps/kubevirt-ssp-operator created
deployment.apps/cdi-operator created
deployment.apps/node-maintenance-operator created
+ kubectl create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/hco.cr.yaml
hyperconverged.hco.kubevirt.io/hyperconverged-cluster created
```

The result is a new namespace called `kubevirt-hyperconverged` with all the operators, Custom Resources (CRs) and objects needed by KubeVirt:

```sh
$ kubectl get pods -n kubevirt-hyperconverged -o wide
NAME                                                  READY   STATUS    RESTARTS   AGE   IP                NODE                            NOMINATED NODE   READINESS GATES
bridge-marker-bwq6f                                   1/1     Running   0          12m   192.168.123.250   blog-master-00.kubevirt.local   <none>           <none>
bridge-marker-st7f7                                   1/1     Running   0          12m   192.168.123.232   blog-worker-00.kubevirt.local   <none>           <none>
cdi-apiserver-6f59996849-2hmm9                        1/1     Running   0          12m   10.244.1.17       blog-worker-00.kubevirt.local   <none>           <none>
cdi-deployment-57c68dbddc-c4n8l                       1/1     Running   0          12m   10.244.1.22       blog-worker-00.kubevirt.local   <none>           <none>
cdi-operator-64bbf595c-48v7k                          1/1     Running   1          24m   10.244.1.12       blog-worker-00.kubevirt.local   <none>           <none>
cdi-uploadproxy-5cbf6f4897-95fn5                      1/1     Running   0          12m   10.244.1.16       blog-worker-00.kubevirt.local   <none>           <none>
cluster-network-addons-operator-5956598648-5r79l      1/1     Running   0          24m   10.244.1.10       blog-worker-00.kubevirt.local   <none>           <none>
hyperconverged-cluster-operator-d567b5dd8-7d8wq       0/1     Running   0          24m   10.244.1.9        blog-worker-00.kubevirt.local   <none>           <none>
kube-cni-linux-bridge-plugin-kljvq                    1/1     Running   0          12m   10.244.1.19       blog-worker-00.kubevirt.local   <none>           <none>
kube-cni-linux-bridge-plugin-p6dkz                    1/1     Running   0          12m   10.244.0.7        blog-master-00.kubevirt.local   <none>           <none>
kube-multus-ds-amd64-84gcj                            1/1     Running   1          12m   10.244.1.23       blog-worker-00.kubevirt.local   <none>           <none>
kube-multus-ds-amd64-flq8s                            1/1     Running   2          12m   10.244.0.10       blog-master-00.kubevirt.local   <none>           <none>
kubemacpool-mac-controller-manager-675ff47587-pb57c   1/1     Running   0          11m   10.244.1.20       blog-worker-00.kubevirt.local   <none>           <none>
kubemacpool-mac-controller-manager-675ff47587-rf65j   1/1     Running   0          11m   10.244.0.8        blog-master-00.kubevirt.local   <none>           <none>
kubevirt-ssp-operator-7b5dcb45c4-qd54h                1/1     Running   0          24m   10.244.1.11       blog-worker-00.kubevirt.local   <none>           <none>
nmstate-handler-8r6d5                                 1/1     Running   0          11m   192.168.123.232   blog-worker-00.kubevirt.local   <none>           <none>
nmstate-handler-cq5vs                                 1/1     Running   0          11m   192.168.123.250   blog-master-00.kubevirt.local   <none>           <none>
node-maintenance-operator-7f8f78c556-q6flt            1/1     Running   0          24m   10.244.0.5        blog-master-00.kubevirt.local   <none>           <none>
ovs-cni-amd64-4z2qt                                   2/2     Running   0          11m   192.168.123.250   blog-master-00.kubevirt.local   <none>           <none>
ovs-cni-amd64-w8fzj                                   2/2     Running   0          11m   192.168.123.232   blog-worker-00.kubevirt.local   <none>           <none>
virt-api-7b7d486d88-hg4rd                             1/1     Running   0          11m   10.244.1.21       blog-worker-00.kubevirt.local   <none>           <none>
virt-api-7b7d486d88-r9s2d                             1/1     Running   0          11m   10.244.0.9        blog-master-00.kubevirt.local   <none>           <none>
virt-controller-754466fb86-js6r7                      1/1     Running   0          10m   10.244.1.25       blog-worker-00.kubevirt.local   <none>           <none>
virt-controller-754466fb86-mcxwd                      1/1     Running   0          10m   10.244.0.11       blog-master-00.kubevirt.local   <none>           <none>
virt-handler-cz7q2                                    1/1     Running   0          10m   10.244.0.12       blog-master-00.kubevirt.local   <none>           <none>
virt-handler-k6npr                                    1/1     Running   0          10m   10.244.1.24       blog-worker-00.kubevirt.local   <none>           <none>
virt-operator-84f5588df6-2k49b                        1/1     Running   0          24m   10.244.1.14       blog-worker-00.kubevirt.local   <none>           <none>
virt-operator-84f5588df6-zzrsb                        1/1     Running   1          24m   10.244.0.4        blog-master-00.kubevirt.local   <none>           <none>
```

Note that once HCO is deployed we can manage VirtualMachines and VirtualMachineTemplates from the web console. This is because the web console is shipped with a KubeVirt plugin that detects a KubeVirt installation in our Kubernetes cluster and enables automatically the plugin in the web console.

<iframe width="1110" height="650" src="https://www.youtube.com/embed/TOqqXWCX64o" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


## Containerized installation

Taking into account that the OKD web console runs as a pod in OKD along with its deployment, services and all objects needed to run properly. The idea is to take advantage of the containerized OKD web console available and execute in one of the nodes of our native Kubernetes cluster. 

`Note that unlike the binary installation the pod must run in a node inside our Kubernetes cluster`. On the other side, running the OKD web console as a native Kubernetes application will benefit from all the Kubernetes advantages: rolling deployments, easy upgrades, high availability, scalability, auto restart in case of failure, liveness and readiness probes... We will see an example how easy will be to update our OKD web console to a newest version.


### Deploying OKD web console 

In order to configure the deployment of the OKD web console we need to create the proper Kubernetes objects. As we saw in the previous section [Compiling OKD web console](#compiling-okd-web-console) there are quite a few environment variables that needs to be set. When dealing with Kubernetes objects this variables should be included in the deployment object.

We already created the deployment and service objects in a yaml file that mimic the binary installation. Then, first download the [yaml file]() and modify the value depending on your local installation. 

Execute the environment.sh script and check the ouput paying attention to the variables and values exported:

```sh
$ bash -x contrib/environment.sh 
+ export BRIDGE_USER_AUTH=disabled
+ BRIDGE_USER_AUTH=disabled
+ export BRIDGE_K8S_MODE=off-cluster
+ BRIDGE_K8S_MODE=off-cluster
++ kubectl config view -o json
++ jq '{myctx: .["current-context"], ctxs: .contexts[], clusters: .clusters[]}'
++ jq .clusters.cluster.server -r
++ jq 'select(.ctxs.context.cluster ==  .clusters.name)'
++ jq 'select(.myctx == .ctxs.name)'
+ BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT=https://192.168.123.250:6443
+ export BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT
+ export BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS=true
+ BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS=true
+ export BRIDGE_K8S_AUTH=bearer-token
+ BRIDGE_K8S_AUTH=bearer-token
++ kubectl get serviceaccount console --namespace=kube-system -o 'jsonpath={.secrets[0].name}'
+ secretname=console-token-ppfc2
++ kubectl get secret console-token-ppfc2 --namespace=kube-system -o template '--template={{.data.token}}'
++ base64 --decode
+ BRIDGE_K8S_AUTH_BEARER_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6InJseElWc2dRVTZIbHlKTE5ablVzZWNpWkt6YjBjczdnZ0p4X1JRWEtLWEEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjb25zb2xlLXRva2VuLXBwZmMyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNvbnNvbGUiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI3MmIyYTU4ZS00Y2I1LTRjOGQtYjhjNy1mMDAwOWEzNWZhNWYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06Y29uc29sZSJ9.kHgsjYpGCVlsO9_yUN2_KVF8Fd9IDUV4gN5PM_v4SckEv9GPfF8UJ2M9f4KugKs2rVxKEWoxCLju6JE87rrzT_PAOv4ANNrbErl93hDFAqr56Wd39RImUjog096PqM0A-VO-eTlnPMk9hKr5Avrr2aSuBR_JR0J5qoKl4PCubQacoQh_bIW5SY5l-c6Nl9VEPNm_51iSi7GKdLRe0kQxMxp1xMlj2LUhsLPPqyuMTL2Se-9AU_FLzKC2qJbXdSV_8a-fRqKZKKDQwq_xhg-1QNSs5yd44cUnhZEzD61qXV5EbxerQvpVsC0Z4UVzjqP-tcVIjswLishxZ4ZaLsHTow
+ export BRIDGE_K8S_AUTH_BEARER_TOKEN
+ echo 'Using https://192.168.123.250:6443'
Using https://192.168.123.250:6443

```

Below, modify the downloaded yaml file and assign the proper values to the variables and token:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: console-deployment
  namespace: kube-system
  labels:
    app: console
spec:
  replicas: 1
  selector:
    matchLabels:
      app: console
  template:
    metadata:
      labels:
        app: console
    spec:
      containers:
      - name: console-app
        image: quay.io/openshift/origin-console:4.2
        env:
        - name: BRIDGE_USER_AUTH
          value: disabled         # no authentication required
        - name: BRIDGE_K8S_MODE
          value: off-cluster
        - name: BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT
          value: https://192.168.123.250:6443  #master api
        - name: BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS
          value: "true"           # no tls enabled
        - name: BRIDGE_K8S_AUTH
          value: bearer-token
        - name: BRIDGE_K8S_AUTH_BEARER_TOKEN
          valueFrom:
            secretKeyRef:
              name: console-token-ppfc2 # console serviceaccount token
              key: token

---
kind: Service
apiVersion: v1
metadata:
  name: console-np-service
  namespace: kube-system
spec:
  selector:
    app: console
  type: NodePort    # nodePort configuration
  ports:
  - name: http
    port: 9000
    targetPort: 9000
    nodePort: 30036
    protocol: TCP

---
```

Finally, create both objects: deployment and service. The deployment will trigger the deploy of the OKD web console image.

```sh
$ kubectl create -f okd-web-console-install.yaml 
deployment.apps/console-deployment created
service/console-service created

$ kubectl get pods -o wide -n kube-system
NAME                                                    READY   STATUS    RESTARTS   AGE     IP                NODE                            NOMINATED NODE   READINESS GATES
console-deployment-59d8956db5-td462                     1/1     Running   0          4m49s   10.244.0.13       blog-master-00.kubevirt.local   <none>           <none>

$ kubectl get svc -o wide -n kube-system
NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
console-np-service   NodePort    10.96.195.45   <none>        9000:30036/TCP           19m
kube-dns             ClusterIP   10.96.0.10     <none>        53/UDP,53/TCP,9153/TCP   20d
```

Next we can connect to the nodeport we defined in the service object and check that the OKD web console is up and running version 4.2.


<img src="/assets/2020-01-07-OKD-web-console-install/okd-pod-4.2.resized.png" alt="OKD 4.2">


Verify that we can see and manage VirtualMachines that are running inside our native Kubernetes cluster.


<img src="/assets/2020-01-07-OKD-web-console-install/okd-console-vm.resized.png" alt="OKD vmr">



### Upgrade OKD web console 

The upgrade process is really easy, we just need to check the versions available in the Openshift console image repository and modify the deployment object to run the desired version of the OKD web console.

<img src="/assets/2020-01-07-OKD-web-console-install/quay-okd-repo.resized.png" alt="OKD vmr">


In this case we are going to update and take a look at the newest version which is 4.5.0/4.5. Note that this is not linked with the latest tag, actually `latest` tag it is the same as version `4.4`. Upgrading is just modifying the image value to the new container image: `quay.io/openshift/origin-console:4.5` and save

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: console-deployment
  namespace: kube-system
  labels:
    app: console
spec:
  replicas: 1
  selector:
    matchLabels:
      app: console
  template:
    metadata:
      labels:
        app: console
    spec:
      containers:
      - name: console-app
        image: quay.io/openshift/origin-console:4.5 #new image version
        env:
        - name: BRIDGE_USER_AUTH
          value: disabled
        - name: BRIDGE_K8S_MODE
          value: off-cluster
        - name: BRIDGE_K8S_MODE_OFF_CLUSTER_ENDPOINT
          value: https://192.168.123.250:6443
        - name: BRIDGE_K8S_MODE_OFF_CLUSTER_SKIP_VERIFY_TLS
          value: "true"
        - name: BRIDGE_K8S_AUTH
          value: bearer-token
        - name: BRIDGE_K8S_AUTH_BEARER_TOKEN
          valueFrom:
            secretKeyRef:
              name: console-token-ppfc2
              key: token

```
Once you save the deployment a new pod with the new version of the OKD web console is being created and eventually will replace the old one.

```sh
$ kubectl get pods -n kube-system
NAME                                                    READY   STATUS              RESTARTS   AGE
console-deployment-5588f98644-bw7jr                     0/1     ContainerCreating   0          5s
console-deployment-59d8956db5-td462                     1/1     Running             0          16h
```

<img src="/assets/2020-01-07-OKD-web-console-install/okd-console-4.5.resized.png" alt="OKD web console 4.5">


## Summary

In this post `we explored two ways to install the OKD web console to manage our KubeVirt deployment in a native Kubernetes cluster`. Running the OKD web console will allow us to create, manage and delete virtual machines running in a native cluster from a friendly user interface. Also we will be able to delegate to our developers or other users the creation and maintenance of their virtual machines without having deep knowledge of Kubernetes.

Personally, I would like to see more user interfaces to manage and configure KubeVirt deployments and their virtual machines. In our previous post [KubeVirt user interface options](https://kubevirt.io/2019/KubeVirt_UI_options.html) we explore some options, however only OKD web console was found to be deeply integrated with KubeVirt. 

Ping us or comment this post in case there are some other options we did not notice.