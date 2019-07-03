---
layout: post
author: mmazur
title: KubeVirt with Ansible, part 1 – Introduction
description: With the release of Ansible 2.8 comes a new set of KubeVirt modules
navbar_active: Blogs
pub-date: May 21
pub-year: 2019
category: news
comments: true
---

KubeVirt is a great solution for migrating existing workloads towards Kubernetes without having to containerize
everything all at once (or at all).
If some parts of your system can run as pods, while others are perfectly fine as virtual machines, KubeVirt is the
technology that lets you seamlessly run both in a single cluster.

And with the recent release of Ansible 2.8 containing a new set of dedicated modules, it's now possible to treat KubeVirt
just like any other ansible–supported VM hosting system. Already an Ansible user? Or maybe still researching your options?
This series of posts should give you a good primer on how combining both technologies can ease your Kubernetes journey.

## Prerequisites

While it's possible to specify the connection and authentication details of your k8s cluster directly in the
playbook, for the purpose of this introduction, we'll assume you have a working kubeconfig file in your system. If
running `kubectl get nodes` correctly returns a list of nodes and you've already deployed KubeVirt, then you're
good to go. If not, here's a [KubeVirt quickstart (with Minikube)][quickstart minikube].

[quickstart minikube]: https://kubevirt.io/quickstart_minikube/

## Basic VM management

Before we get down to the YAML, please keep in mind that this post contains only the most interesting bits of the playbooks.
To get actually runnable versions of each example, take a look at [this code repository][examples repo].

[examples repo]: https://github.com/kubevirt/ansible-kubevirt-modules/tree/master/examples/blog/part1

Let's start with creating the most basic VM by utilizing the *kubevirt_vm* module, like so:

```yaml
kubevirt_vm:
  namespace: default
  name: vm1
  state: running
```

And now run it:

```console
[mmazur@klapek blog1]$ ansible-playbook 01_vm1_running.yaml
(…)
TASK [Create first vm?] *******************************************************************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "It's impossible to create an empty VM or change state of a non-existent VM."}

PLAY RECAP ********************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

Oops, too basic. Let's try again, but this time with a small set of parameters specifying cpu, memory and a boot disk.
The latter will be a demo image provided by the KubeVirt project.

```yaml
kubevirt_vm:
  namespace: default
  name: vm1
  cpu_cores: 1
  memory: 64Mi
  disks:
    - name: containerdisk
      volume:
        containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
      disk:
        bus: virtio
```

And run it:

```console
[mmazur@klapek blog1]$ ansible-playbook 02_vm1.yaml
(…)
TASK [Create first vm, for real this time] ************************************************************************
changed: [localhost]

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

It worked! One thing to note is that by default *kubevirt_vm* will not start a newly–created VM. Running `kubectl get vms -n default` will confirm as much.

Changing this behavior requires specifying `state: running` as one of the module's parameters when creating a new VM. Or we can get _vm1_ to
boot by running the first playbook one more time, since this time the task will be interpreted as attempting to change the _state_ of
an existing VM to _running_, which is what we want.

```console
[mmazur@klapek blog1]$ ansible-playbook 01_vm1_running.yaml
(…)
TASK [Create first vm] ********************************************************************************************
changed: [localhost]

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

While the first two runs likely finished almost immediately, this time around `ansible-playbook` is waiting for the VM to boot, so
don't be alarmed if that takes a bit of time.

If everything went correctly, you should have an actual virtual machine running inside your k8s cluster. If present, the `virtctl` tool
can be used to log onto the new VM and to take a look around. Run `virtctl console vm1 -n default` and press _ENTER_ to get a login prompt.

It's useful to note at this point something about how Ansible and Kubernetes operate. This is best illustrated with an example. Let's run
the first playbook one more time:

```console
[mmazur@klapek blog1]$ ansible-playbook 01_vm1_running.yaml
(…)
TASK [Create first vm?] *******************************************************************************************
ok: [localhost]

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The output is almost the same as on the previous run, with the one difference being that this time no changes were reported (`changed=0`).
This is a concept called idempotency and is present in both Kubernetes and Ansible (though not everywhere).
In this context it means that if the state you want to achieve with your playbook (have the VM running) is the state that the cluster
currently is in (the VM is already running) then nothing will change, no matter how many times you attempt the operation.

__NOTE:__ Kubernetes versions prior to 1.12 contain a bug that might report operations that didn't really do anything as having
changed things. If your second (and third, etc.) run of `01_vm1_running.yaml` keep reporting `changed=1`, this might be the reason why.

Let's finish with cleaning up after ourselves by removing _vm1_. First the relevant YAML:

```yaml
kubevirt_vm:
  namespace: default
  name: vm1
  state: absent
```

And run it:

```console
[mmazur@klapek blog1]$ ansible-playbook 03_vm1_absent.yaml
(…)
TASK [Delete the vm] **********************************************************************************************
changed: [localhost]

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Now the VM is gone, which running `kubectl get vms -n default` will confirm.
Just like before, if you run the playbook a few more times, the _play recap_ will keep reporting `changed=0`.


## Next

Please read [part two][part 2] for a wider overview of available features.

[part 2]: https://kubevirt.io/2019/kubevirt-with-ansible-part-2.html
