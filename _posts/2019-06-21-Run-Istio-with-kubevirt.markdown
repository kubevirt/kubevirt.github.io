---
layout: post
author: SchSeba
description: Use istio with kubevirt
---

# Introduction

On this blog post, we are going to deploy virtual machines with the kubevirt project and insert them into the istio service mesh.

This demo is going to be deployed on a k8s 1.10 cluster.


# Requirements

* docker
* kubeadm

Follow this [document](https://kubernetes.io/docs/tasks/tools/install-kubeadm/) to install everything we need for the POC


# Deployment

For the POC we clone [this repo](https://github.com/SchSeba/kubevirt-istio-poc)

Run the bash script

```
cd kubevirt-istio-poc
./deploy-istio-poc.sh
```

# Demo application

We are going to use the [bookinfo sample application](https://istio.io/docs/guides/bookinfo/#overview) from the istio webpage

The follow yaml will deploy the bookinfo application with a 'small' change the details service will run on a virtual machine!

<span style="color:blue;">Note: it will take like 5 minutes for the application to by running inside the virtual machine because we install git and ruby, then clone the istio repo and start the application</span>

# POC details

Lets start with the bash script:

```
#!/bin/bash

set -x

kubeadm init --pod-network-cidr=192.168.0.0/16

yes | cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

ready=$(kubectl get po -n kube-system | grep kube-dns | grep Running | wc -l)

while [ $ready -eq 0 ]
do
        echo Calico deployment is no ready yet.
        sleep 5
        ready=$(kubectl get po -n kube-system | grep kube-dns | grep Running | wc -l)
done

echo Calico is ready.

echo Taint the master node.

kubectl taint nodes --all node-role.kubernetes.io/master-

echo Deploy kubevirt.

kubectl apply -f kubevirt.yaml

echo Deploy istio.

kubectl apply -f istio-demo-auth.yaml

echo Add istio-injection to the default namespace.

kubectl label namespace default istio-injection=enabled 


ready=$(kubectl get po -n istio-system | grep sidecar-injector | grep Running | wc -l)

while [ $ready -eq 0 ]
do
        echo Istio deployment is no ready yet.
        sleep 5
        ready=$(kubectl get po -n istio-system | grep sidecar-injector | grep Running | wc -l)
done

echo Istio is ready.

sleep 20

echo Deploy the bookinfo example application

kubectl apply -f bookinfo.yaml

kubectl apply -f bookinfo-gateway.yaml
```

The follow script create a kubernetes cluster using the kubeadm command, deploy calico as a network CNI and taint the master node (have only one node in the cluster).

After the cluster is up the script deploy both istio with mutual TLS and kubevirt projects, it also add the auto injection to the default namespace.

At last the script deploy the bookinfo demo application that we change a bit.

Lets take a closer look in the virtual machine part inside the bookinfo.yaml file

```
##################################################################################################
# Details service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
  labels:
    special: vmi-details
    app: details
    version: v1
  name: vmi-details
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: registrydisk
        volumeName: registryvolume
      - disk:
          bus: virtio
        name: cloudinitdisk
        volumeName: cloudinitvolume
      interfaces:
      - name: testSlirp
        slirp:
          ports:
          - name: http
            port: 9080
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  networks:
  - name: testSlirp
    pod: {}
  terminationGracePeriodSeconds: 0
  volumes:
  - name: registryvolume
    registryDisk:
      image: kubevirt/fedora-cloud-registry-disk-demo:latest
  - cloudInitNoCloud:
      userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
        yum install git ruby -y
        git clone https://github.com/istio/istio.git
        cd istio/samples/bookinfo/src/details/
        ruby details.rb 9080 &
    name: cloudinitvolume
status: {}
---
..........
```

### Details:

* Create a network of type pod

```
networks:
- name: testSlirp
  pod: {}
```

* Create an interface of type slirp and connect it to the pod network by matching the pod network name
* Add our application port in the slirp interface

```
interfaces:
- name: testSlirp
  slirp:
    ports:
    - name: http
      port: 9080
```

* Use the cloud init script to download install and run the details application

```
- cloudInitNoCloud:
    userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
        yum install git ruby -y
        git clone https://github.com/istio/istio.git
        cd istio/samples/bookinfo/src/details/
        ruby details.rb 9080 &
    name: cloudinitvolume
```

# POC Check

After running the bash script the environment should look like this

```
NAME                              READY     STATUS    RESTARTS   AGE
productpage-v1-7bbdd59459-w6nwq   2/2       Running   0          1h
ratings-v1-76dc7f6b9-6n6s9        2/2       Running   0          1h
reviews-v1-64545d97b4-tvgl2       2/2       Running   0          1h
reviews-v2-8cb9489c6-wjp9x        2/2       Running   0          1h
reviews-v3-6bc884b456-hr5bm       2/2       Running   0          1h
virt-launcher-vmi-details-94pb6   3/3       Running   0          1h
```

Lets find the istio ingress service port

```
# kubectl get service -n istio-system  | grep istio-ingressgateway
istio-ingressgateway       LoadBalancer   10.97.163.91     <pending>     80:31380/TCP,443:31390/TCP,31400:31400/TCP                            3h
```

Then browse the follow url

```
http://<k8s-node-ip-address>:<istio-ingress-service-port-exposed-by-k8s>/productpage
```

Example:
```
http://10.0.0.1:31380/productpage
```

# Conclusions

This POC show how we can use istio with kubevirt and integrate the istio service mesh to virtual machines running inside our kubernetes cluster.