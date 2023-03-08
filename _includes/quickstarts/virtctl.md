## Virtctl

KubeVirt provides an additional binary called _virtctl_ for quick access to the serial and graphical ports of a VM and also handle start/stop operations.

### Install
`virtctl` can be retrieved from the release page of the KubeVirt github page.

* Run the following:
```bash
VERSION=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/') || windows-amd64.exe
echo ${ARCH}
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl
sudo install virtctl /usr/local/bin
```

### Install as Krew plugin
`virtctl` can be installed as a plugin via the [`krew` plugin manager](https://krew.dev/). Occurrences of `virtctl <command>...` can then be read as `kubectl virt <command>...`.  

* Run the following to install:
```bash
kubectl krew install virt
```
<br>
