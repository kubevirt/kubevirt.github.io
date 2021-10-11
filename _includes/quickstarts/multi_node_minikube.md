### Multi-Node Minikube

Minikube has support for adding additional nodes to a cluster. This can be
helpful in experimenting with KubeVirt on minikube as some operations like node
affinity or live migration require more than one cluster node to demonstrate.

#### Container Network Interface

By default, minikube sets up a kubernetes cluster using either a virtual
machine appliance or a container. For a single node setup, local network
connectivity is sufficient. In the case where multiple nodes are involved, even
when using containers or VMs on the same host, kubernetes needs to define a
shared network to allow pods on one host to communicate with pods on the other
host. To this end, minikube supports a number of [Container Network Interface
(CNI) plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
the simplest of which is [flannel](https://github.com/flannel-io/flannel#flannel).

#### Updating the minikube start command

To have minikube start up with the flannel CNI plugin over two nodes, alter the minikube start command:

```bash
minikube start --nodes=2 --cni=flannel
```
