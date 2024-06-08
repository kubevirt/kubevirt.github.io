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
      url: "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-AmazonEC2.x86_64-40-1.14.raw.xz"
EOF

kubectl create -f dv_fedora.yml
