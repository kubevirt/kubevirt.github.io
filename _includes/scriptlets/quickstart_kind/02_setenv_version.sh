# On other OS you might need to define it like
export KUBEVIRT_VERSION="v0.25.0"

# On Linux you can obtain it using 'curl' via:
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases|grep tag_name|sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs | cut -d'-' -f1)

echo $KUBEVIRT_VERSION
