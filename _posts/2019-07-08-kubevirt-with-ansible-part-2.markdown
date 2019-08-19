---
layout: post
author: mmazur
title: KubeVirt with Ansible, part 2
description: A deeper dive into Ansible 2.8's KubeVirt features
navbar_active: Blogs
pub-date: 8 Jul
pub-year: 2019
category: news
comments: true
---

[Part 1][blog part 1] contained a short introduction to basic VM management with Ansible's `kubevirt_vm` module.
This time we'll paint a more complete picture of all the features on offer.

As before, examples found herein are also available as full working playbooks in our
[playbooks example repository][blog examples].
Additionally, each section of this post links to the corresponding module's Ansible documentation page.
Those pages always contain an _Examples_ section, which the reader is encouraged to look through, as they have
many more ways of using the modules than can reasonably fit here.

[blog part 1]: {% post_url 2019-05-21-kubevirt-with-ansible-part-1 %}
[blog examples]: https://github.com/kubevirt/ansible-kubevirt-modules/tree/master/examples/blog


## More VM management


Virtual machines managed by KubeVirt are highly customizable. Among the features accessible from Ansible, are:

* various libvirt–level virtualized hardware tweaks (e.g. `machine_type` or `cpu_model`),
* network interface configuration (`interfaces`), including multi–NIC utilizing the Multus CNI,
* non–persistent VMs (`ephemeral: yes`),
* direct DataVolumes support (`datavolumes`),
* and OpenShift Templates support (`template`).

[datavols]: {% post_url 2018-10-10-CDI-DataVolumes %}

### Further resources

* [Ansible module documentation](https://docs.ansible.com/ansible/latest/modules/kubevirt_vm_module.html)
  * [Examples, lots of examples](https://docs.ansible.com/ansible/latest/modules/kubevirt_vm_module.html#examples)
* DataVolumes
  * [Introductory blog post]({% post_url 2018-10-10-CDI-DataVolumes %})
  * [Upstream documentation](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/datavolumes.md)
* Multus
  * [Introductory blog post]({% post_url 2018-09-12-attaching-to-multiple-networks %})
  * [GitHub repo](https://github.com/intel/multus-cni)



## VM Image Management with the Containerized Data Importer

The main functionality of the `kubevirt_pvc` module is to manage Persistent Volume Claims. The following snippet
should seem familiar to anyone who dealt with PVCs before:

```yaml
kubevirt_pvc:
  name: pvc1
  namespace: default
  size: 100Mi
  access_modes:
    - ReadWriteOnce
```

Running it inside a playbook will result in a new PVC named _pvc1_ with the access mode _ReadWriteOnce_ and at least
100Mi of storage assigned.

The option dedicated to working with VM images is named `cdi_source` and lets one fill a PVC with data immediately
upon creation. But before we get to the examples, the Containerized Data Importer needs to be properly deployed,
which is as simple as running the following commands:

```bash
export CDI_VER=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VER/cdi-operator.yaml
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VER/cdi-cr.yaml
```

Once `kubectl get pods -n cdi` confirms all pods are ready, CDI is good to go.

The module can instruct CDI to fill the PVC with data from:
* a remote HTTP(S) server (`http:`),
* a container registry (`registry:`),
* a local file (`upload: yes`), though this requires using `kubevirt_cdi_upload` for the actual upload step,
* or nowhere (the `blank: yes` option).

Here's a simple example:

```yaml
kubevirt_pvc:
name: pvc2
namespace: default
size: 100Mi
access_modes:
  - ReadWriteOnce
wait: yes
cdi_source:
  http:
    url: https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
```

Please notice the `wait: yes` parameter. The module will only exit after CDI has completed transfering its data.
Let's see this in action:

```bash
[mmazur@klapek part2]$ ansible-playbook pvc_cdi.yaml
(…)

TASK [Create pvc and fetch data] **********************************************************************************
changed: [localhost]

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[mmazur@klapek part2]$ kubectl get pvc
NAME      STATUS    VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc2      Bound     local-pv-6b6380e2   37Gi       RWO            local          71s
[mmazur@klapek part2]$ kubectl get pvc/pvc2 -o yaml|grep cdi
    cdi.kubevirt.io/storage.import.endpoint: https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
    cdi.kubevirt.io/storage.import.importPodName: importer-pvc2-gvn5c
    cdi.kubevirt.io/storage.import.source: http
    cdi.kubevirt.io/storage.pod.phase: Succeeded
```

Everything worked as expected.


### Further resources

* [Ansible module documentation (kubevirt_pvc)](https://docs.ansible.com/ansible/latest/modules/kubevirt_pvc_module.html)
* [Ansible module documentation (kubevirt_cdi_upload)](https://docs.ansible.com/ansible/latest/modules/kubevirt_cdi_upload_module.html)
* [CDI GitHub Repo](https://github.com/kubevirt/containerized-data-importer/)



## Inventory plugin

The default way of using Ansible is to iterate over a list of hosts and perform operations on each one.
Listing KubeVirt VMs can be done using the KubeVirt inventory plugin. It needs a bit of setting up before it can
be used.

First, enable the plugin in `ansible.cfg`:

```config
[inventory]
enable_plugins = kubevirt
```

Then configure the plugin using a file named `kubevirt.yml` or `kubevirt.yaml`:

```yaml
plugin: kubevirt
connections:
  - namespaces:
      - default
    network_name: default
```

And now let's see if it worked and there's a VM running in the default namespace (as represented by the
`namespace_default` inventory group):

```bash
[mmazur@klapek part2]$ ansible -i kubevirt.yaml namespace_default --list-hosts
 [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not
match 'all'

  hosts (0):
```

Right, we don't have any VMs running. Let's go back to [part 1][blog part 1], create `vm1`, make sure it's runing
and then try again:

```bash
[mmazur@klapek part2]$ ansible-playbook  ../part1/02_vm1.yaml
(…)
PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[mmazur@klapek part2]$ ansible-playbook  ../part1/01_vm1_running.yaml
(…)
PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[mmazur@klapek part2]$ ansible -i kubevirt.yaml namespace_default --list-hosts
  hosts (1):
    default-vm1-2c680040-9e75-11e9-8839-525500d15501
```

Works!


### Further resources

* [Ansible inventory plugin documentation](https://docs.ansible.com/ansible/latest/plugins/inventory/kubevirt.html)



## More

Lastly, for the sake of brevity, a quick mention of the remaining modules:

* [kubevirt_presets](https://docs.ansible.com/ansible/latest/modules/kubevirt_preset_module.html) allows setting up
VM presets to be used by deployed VMs,
* [kubevirt_template](https://docs.ansible.com/ansible/latest/modules/kubevirt_template_module.html) brings in a generic
templating mechanism, when running on top of OpenShift or OKD,
* and [kubevirt_rs](https://docs.ansible.com/ansible/latest/modules/kubevirt_rs_module.html) lets one configure KubeVirt's
own ReplicaSets for running multiple instances of a specified virtual machine.
