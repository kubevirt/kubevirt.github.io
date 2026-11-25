cat <<EOF > dv_fedora.yml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: "fedora"
spec:
  storage:
    resources:
      requests:
        storage: 5Gi
  source:
    http:
      url: "https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
EOF

kubectl create -f dv_fedora.yml
