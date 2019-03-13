# Creating a virtual machine
kubectl apply -f https://raw.githubusercontent.com/kubevirt/kubevirt.github.io/master/labs/manifests/vm.yaml

# After deployment you can manage VMs using the usual verbs:
kubectl get vms
kubectl get vms -o yaml testvm

# To start an offline VM you can use
./virtctl start testvm
kubectl get vmis
kubectl get vmis -o yaml testvm

# To shut it down again
./virtctl stop testvm

# To delete
kubectl delete vms testvm
# To create your own
kubectl create -f $YOUR_VM_SPEC
