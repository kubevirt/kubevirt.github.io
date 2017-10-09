# Run VMs on Kubernetes

The high level goal of the project is to build a Kubernetes add-on to enable
management of virtual machines ([KVM](https://www.linux-kvm.org)), via
[libvirt](https://libvirt.org).

The intent is that over the long term this would enable application container
workloads, and virtual machines, to be managed from a single place via the
[Kubernetes](https://kubernetes.io) native API and objects.
This will

* Provide a migration path to Kubernetes for existing applications deployed in
  virtual machines, allowing them to more seemlessly integrate with application
  container and take advantage of Kubernetes concepts
* Provide a converged API and object model for tenant users needing to manage
  both application containers and full OS image virtual machines
* Provide converged infrastructure for administrators wishing to support both
  application containers and full machine virtualization concurrently
* Facilitate the creation of virtual compute nodes to use KVM to strongly isolate
  application container pods belonging to tenant users with differing trust
  levels

Read more about the [motivation for KubeVirt](about) and [our
use-cases](use-cases).

* [Code of conduct](conduct)

# Getting started

You can get started in several areas - Do you want to start using KubeVirt?
Or rather start coding? Take a look below to see where you can get started.

## As a user

If you have [minikube](https://github.com/kubernetes/minikube/) setup already,
then you can start right away by calling:

```bash
curl run.kubevirt.io/demo.sh | bash
```

Once it is deployed, take a look at the user documentation
<https://kubevirt.gitbooks.io/user-guide/> to learn how to use KubeVirt.

Otherwise you can read about how to setup `minikube` and deploy KubeVirt at
<https://github.com/kubevirt/demo>.

## Connect

Don't hesitate to reach out if you are getting stuck, or are looking for a
feature, do so by using one of our communication channels:

* Twitter: <https://twitter.com/kubevirt>
* Blog: <https://kubevirt.github.io/blog>
* IRC: [#kubevirt @ irc.freenode.net](https://kiwiirc.com/client/irc.freenode.net/kubevirt)
* Mailinglist: <https://groups.google.com/forum/#!forum/kubevirt-dev>
* Upcoming and past events: 
  [View](https://calendar.google.com/calendar/embed?src=18pc0jur01k8f2cccvn5j04j1g%40group.calendar.google.com&ctz=Etc%2FGMT)
  (18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com)

## Contribute, source, and developers

There are several ways how you can contribute, you can learn about them at
our [contributing guide](contrib) and a detailed contribution
[workflow guide](contrib-workflow).

As a developer you can get started with the
[developer setup](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md).

* Sources: <https://github.com/kubevirt/>
* Technical documentation:
  <https://github.com/kubevirt/kubevirt/tree/master/docs>
* Community planning: <https://github.com/kubevirt/community/>
