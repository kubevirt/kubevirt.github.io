## Experiment with CDI

[CDI](https://github.com/kubevirt/containerized-data-importer) is an utility designed to import Virtual Machine images for use with Kubevirt. 

At a high level, a persistent volume claim (PVC) is created. A custom controller watches for importer specific claims, and when discovered, starts an import process to create a raw image named *disk.img* with the desired content into the associated PVC

#### Install CDI

To install the components, we will first explore and then execute the `cdi.sh` script in root's home directory. Be sure to review the contents of this file first. Notice that in the script you are downloading a few yaml files as well, which will be applied to OpenShift. Take a minute to review those files too.

```
cat ~/cdi.sh
~/cdi.sh
```

Review the objects that were added.

```
oc get project| grep golden
oc get pods --namespace=golden-images
```

#### Use CDI

As an example, we will import a Fedora28 Cloud Image as a PVC and launch a Virtual Machine making use of it.

```
oc project myproject
oc create -f pvc_fedora.yml
```

This will create the PVC with a proper annotation so that CDI controller detects it and launches an importer pod to gather the image specified in the *kubevirt.io/storage.import.endpoint* annotation.

```
oc get pvc fedora -o yaml
oc get pod
# replace with your importer pod name
oc logs importer-fedora-pnbqh   # Substitute your importer-fedora pod name here.
```

Notice that the importer downloaded the publically available Fedora Cloud qcow image. Once the importer pod completes, this PVC is ready for use in kubevirt.

Let's create a Virtual Machine making use of it. Review the file *vm1_pvc.yml*.

```
cat ~/vm1_pvc.yml
```

We change the yaml definition of this Virtual Machine to inject the default public key of root user in the GCP Virtual Machine.

```
PUBKEY=`cat ~/.ssh/id_rsa.pub`
sed -i "s%ssh-rsa.*%$PUBKEY%" vm1_pvc.yml
oc create -f vm1_pvc.yml
```

This will create and start a Virtual Machine named vm1. We can use the following command to check our Virtual Machine is running and to gather its IP. You are looking for the IP address beside the `virt-launcher` pod.

```
oc get pod -o wide
```

Since we are running an all in one setup, the corresponding Virtual Machine is actually running on the same node, we can check its qemu process.

```
ps -ef | grep qemu | grep vm1
```

Finally, use the gathered ip to connect to the Virtual Machine, create some files, stop and restart the Virtual Machine with virtctl and check how data persists.

```
ssh fedora@VM_IP
```

This concludes this section of the lab.

[Next Lab](../lab8/lab8.md)\
[Previous Lab](../lab6/lab6.md)\
[Home](../../README.md)
