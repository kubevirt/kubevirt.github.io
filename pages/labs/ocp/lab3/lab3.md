## Explore the Environment

A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator

```
oc get pv 
```

By examining hostPath section of one of the existing PVS, we can see how we are using local paths to provide such storage
The *-o yaml* flag allows us to gather full information for the corrresponding object

```
oc get pv pv0001 -o yaml
```

As noted before, `oc cluster up` leverages docker for running
OpenShift. You can see that by checking out the containers and
images that are managed by docker:

```
docker ps
docker images
```

### Label your Node

The OpenShift instance that you have started runs on a single node, localhost.
Label your node so the virt-launcher pod can be scheduled correctly. Confirm the label was applied.

```
oc label node localhost kubevirt.io/schedulable=true
oc get nodes --show-labels
```

## Basic OpenShift Commands

Common OpenShift commands can be found below. There are quite a few more though, so be sure to refer to the [OpenShift CLI reference documentation](https://docs.openshift.org/latest/cli_reference/basic_cli_operations.html#cli-reference-basic-cli-operations). Descriptions for the following commands can be found in the CLI guide too.

```
oc
oc whoami
oc projects
oc project default
oc config view
oc get all
oc status
oc get pods
oc describe pod <pod id>
oc logs -f router-<rest of pod id>
oc types
oc logout
```

Enable oc bash auto-completion. Try to use tab completion with the `oc` command before and after the next activity.

```
oc # Try tabbing for auto-completion now
oc completion bash >> /etc/bash_completion.d/oc_completion
source /etc/bash_completion.d/oc_completion
oc # Try tabbing for auto-completion now
```

#### Log into OpenShift

```
oc login -u system:admin
oc whoami
```

This concludes this section of the lab.

[Next Lab](../lab4/lab4.md)\
[Previous Lab](../lab2/lab2.md)\
[Home](../../README.md)
