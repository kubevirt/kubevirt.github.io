#!/bin/bash

# =============================================================================
# Define Arguments and defaults
# =============================================================================

declare -A DEFAULTS

DEFAULTS[MINISHIFT_HOME]=${HOME}
DEFAULTS[MINISHIFT_BIN]=${DEFAULTS[MINISHIFT_HOME]}/bin
DEFAULTS[MINISHIFT_TARBALL]=${DEFAULTS[MINISHIFT_HOME]}/minishift.tar.gz
DEFAULTS[MINISHIFT_VERSION]=1.30.0
DEFAULTS[KVM_DRIVER_VERSION]=0.10.0
DEFAULTS[KUBEVIRT_VERSION]=0.12.0
DEFAULTS[KUBECONFIG]=${DEFAULTS[MINISHIFT_HOME]}/kubeconfig

function usage() {
   echo "usage: $0 [options]
 -c               - CLEANUP - remove old stuff
 -d               - DEBUG - debug output
 -h               - help: print this message
 -H <directory>   - MINISHIFT_HOME - Where the .minishift cache directory is
 -B <directory>   - MINISHIFT_BIN  - Where the minishift binaries will be
 -m <version>     - MINISHIFT_VERSION
 -K <version>     - KVM_DRIVER_VERSION
 -k <version>     - KUBEVIRT_VERSION
 -C <file>        - KUBECONFIG    - The kubeconfig file
 -v               - VERBOSE - informative output
"
}

function process_args() {
    while getopts "cdhvH:B:m:k:C:" opt; do
        case $opt in
            H )
                MINISHIFT_HOME=$OPTARG
                ;;
            B )
                MINISHIFT_BIN=$OPTARG
                ;;
            m )
                MINISHIFT_VERSION=$OPTARG
                ;;
            K )
                KVM_DRIVER_VERSION=$OPTARG
                ;;
            k )
                KUBEVIRT_VERSION=$OPTARG
                ;;
            C )
                KUBECONFIG=$OPTARG
                ;;
            c ) CLEANUP='true'
                ;;
            d ) DEBUG='true'
                ;;
            v ) VERBOSE='true'
                ;;
            h ) usage
                exit
                ;;
        esac
    done
}

function apply_defaults() {
    for KEY in "${!DEFAULTS[@]}"; do
        if [ -z $(eval 'echo $'${KEY}) ] ; then
            eval "$KEY=${DEFAULTS[$KEY]}"
        fi
    done
}

function apply_defaults() {
    for KEY in "${!DEFAULTS[@]}"; do
        if $(eval "[ $(echo $KEY)z != z ]")  ; then
            eval "$KEY=${DEFAULTS[$KEY]}"
        fi
    done
}

function verbose_args() {
    echo "--- ARGS ---"
    echo "MINISHIFT_HOME=${MINISHIFT_HOME}"
    echo "MINISHIFT_BIN=${MINISHIFT_BIN}"
    echo "MINISHIFT_VERSION=${MINISHIFT_VERSION}"
    echo "KVM_DRIVER_VERSION=${KVM_DRIVER_VERSION}"
    echo "KUBEVIRT_VERSION=${KUBEVIRT_VERSION}"
    echo "KUBECONFIG=${KUBECONFIG}"
    echo "------------"
}

function cleanup() {
    [ -x ${MINISHIFT_BIN}/minishift ] && ${MINISHIFT_BIN}/minishift delete --force
    rm -f ${MINISHIFT_BIN}/{minishift,docker-machine-driver-kvm-centos7,virtctl,kubectl}
    rm -f ${MINISHIFT_TARBALL}
    [ -d ${MINISHIFT_HOME}/.minishift ] && rm -r ${MINISHIFT_HOME}/.minishift
    rm -f ${KUBECONFIG}
}

function cleanup_old_runs() {
    rm -rf ${MINIKUBE_HOME}/.minikube
    rm -f ${KUBECONFIG}
}

# ============================================================================
# Utility Functions
# ============================================================================
function verbose() {
    [ -z "${VERBOSE+x}" ] || echo $*
}

function debug() {
    [ -z "${DEBUG+x}" ] || echo $*
}

# =============================================================================
# Process Functions
# =============================================================================

function define_file_locations() {
    KUBECTL=${MINISHIFT_BIN}/kubectl
    MINIKUBE=${MINISHIFT_BIN}/minikube
    KVM_DRIVER=${MINISHIFT_BIN}/docker-machine-driver-kvm
    VIRTCTL=${MINISHIFT_BIN}/virtctl
}

function create_working_directories() {
    [ -d ${MINISHIFT_BIN} ] || mkdir -p ${MINISHIFT_BIN}
    [ -d ${MINISHIFT_HOME} ] || mkdir -p ${MINISHIFT_HOME}
}

function install_openshift_client() {
    echo installing openshift client
}

function install_kubectl() {
    curl --silent -L -o ${KUBECTL} https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod a+x ${KUBECTL}
}

function install_minishift() {
    verbose installing minishift
    curl -L -o ${MINISHIFT_TARBALL} https://github.com/minishift/minishift/releases/download/v${MINISHIFT_VERSION}/minishift-${MINISHIFT_VERSION}-linux-amd64.tgz

    tar -xzvf ${MINISHIFT_TARBALL} \
        minishift-${MINISHIFT_VERSION}-linux-amd64/minishift \
        --to-stdout >  ${MINISHIFT_BIN}/minishift
    chmod a+x ${MINISHIFT_BIN}/minishift
}

function install_kvm_driver() {
    curl -L -o ${KVM_DRIVER} https://github.com/dhiltgen/docker-machine-kvm/releases/download/v${KVM_DRIVER_VERSION}/docker-machine-driver-kvm-centos7 
    chmod +x ${KVM_DRIVER}
}

function install_virtctl() {
    curl --silent -L -o ${VIRTCTL} https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/virtctl-v${KUBEVIRT_VERSION}-linux-amd64
    chmod a+x ${VIRTCTL}
}

# ============================================================================
# MAIN
# ============================================================================
process_args $@
apply_defaults

[ -z "${VERBOSE+x}" ] || verbose_args

if [ ! -z "${CLEANUP+x}" ] ; then
    cleanup
    exit
fi

define_file_locations
create_working_directories

install_openshift_client
install_minishift
install_kvm_driver
install_virtctl

exit

#yum install centos-release-openshift-origin311
#yum install origin-clients

rm -rf minishift-1.30.0-linux-amd64
rm minishift.tar.gz


curl -L -o ~bin/docker-machine-driver-kvm https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 
chmod +x ~/bin/docker-machine-driver-kvm


curl -L -o minishift.tar.gz https://github.com/minishift/minishift/releases/download/v1.30.0/minishift-1.30.0-linux-amd64.tgz

tar -xzvf minishift.tar.gz minishift-1.30.0-linux-amd64/minishift
cp minishift-1.30.0-linux-amd64/minishift ~/bin
chmod a+x ~/bin/minishift

minishift start

oc login -u system:admin

oc create configmap -n kube-system kubevirt-config --from-literal debug.useEmulation=true


oc create configmap -n kube-system kubevirt-config --from-literal debug.useEmulation=true

oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-privileged

oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-controller

oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-apiserver

oc apply -f https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/kubevirt.yaml

curl -L -o ~/bin/virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/virtctl-v${KUBEVIRT_VERSION}-linux-amd64
chmod +x ~/bin/virtctl


minishift delete --force --clear-cache
