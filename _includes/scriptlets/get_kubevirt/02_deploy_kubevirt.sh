export VERSION={{ site.kubevirt_version }}
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT}/kubevirt-cr.yaml
