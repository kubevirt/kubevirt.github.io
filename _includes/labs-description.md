## Step 2: KubeVirt labs

After you have connected to your instance through SSH, you can
work through a couple of labs to help you get acquainted with KubeVirt
and how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab1). This lab walks
through the creation of a Virtual Machine Instance (VMI) on Kubernetes and then
it is shown how virtctl is used to interact with its console.

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab2). This
lab shows how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer){:target="\_blank"}
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/){:target="\_blank"}
(PVC) and then how to define a VM to make use of the PVC.

The third lab is ["KubeVirt upgrades"](../labs/kubernetes/lab3). This lab shows
how easy and safe is to upgrade your KubeVirt installation with zero down-time.

## Found a bug?

We are interested in hearing about your experience.

If experience a problem with the labs, please report it to the [kubevirt.io issue tracker](https://github.com/kubevirt/kubevirt.github.io/issues){:target="\_blank"}.
