---
layout: ocp
title: Install KubeVirt
permalink: /labs/ocp/lab5
lab: ocp
order: 1
---

# Install KubeVirt

In this section, download the `kubevirt.yaml` file and explore it.  Then, apply it from the upstream github repo.

```
export VERSION=v0.7.0-alpha.2
```

Grab the kubevirt.yaml file to explore. Review the ClusterRole's, CRDs, ServiceAccounts, DaemonSets, Deployments, and Services.

```bash
wget https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt.yaml
less kubevirt.yaml
```

Install KubeVirt. You should see several objects were created.

```bash
oc apply -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt.yaml
```

Define the following policies for OpenShift.

```
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-privileged
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-controller
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-apiserver
```

Give permissions to the qemu user for persistent volume claims

```
setfacl -m user:107:rwx /root/openshift.local.pv/pv*
```


Review the objects that KubeVirt added.

```
oc get sa --all-namespaces | grep kubevirt
oc describe sa kubevirt-apiserver --namespace=kube-system # Please feel free to explore the other objects as well. Get a feel for the expected output.
oc get pods --namespace=kube-system
oc describe pod -l kubevirt.io=virt-handler --namespace=kube-system
# review the files on the root of the filesystem of the pod, see the virt-handler executable, after replacing the pod name with yours
oc exec -it virt-handler-n9pxj --namespace=kube-system ls /  # Substitute your virt-handler pod name
oc get svc --namespace=kube-system
oc describe  svc virt-api --namespace=kube-system
```

There are other services and objects to take a look at.

To review the objects through the OpenShift web console, access the console and log in as the `developer` user at `https://student<number>.cnvlab.gce.sysdeseng.com:8443`. Remember, you can use `oc cluster status` to get your URL.

Open that URL in a browser, log in as the `developer` user with a password of `developer`.

<img src="/assets/images/labs/ocp/openshift-console-login.png" class="img-fluid" alt="Provisioned KubeVirt">

Explore the kube-system project by clicking on the `View All` link in the right hand navigation pane.

<img src="/assets/images/labs/ocp/openshift-console-view-all.png" class="img-fluid" alt="OpenShift">

Browse to the `kube-system` project and explore the objects. Click on the different objects, explore the environment.

<img src="/assets/images/labs/ocp/openshift-console-kube-system.png" class="img-fluid" alt="OpenShift">

#### Install virtctl

Return to the CLI and install virtctl. This tool provides quick access to the serial and graphical ports of a VM, and handle start/stop operations. Also run `virtctl` to get an idea of it's options.

```bash
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
chmod -v +x virtctl
./virtctl --help
```

This concludes this section of the lab.

---

[Next Lab](../ocp/lab6)\
[Previous Lab](../ocp/lab4)\
[Home](../../../labs)
