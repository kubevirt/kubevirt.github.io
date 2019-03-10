#!/bin/bash

# =============================================================================
# Define Arguments and defaults
# =============================================================================

declare -A DEFAULTS

DEFAULTS[MINIKUBE_HOME]=${HOME}
DEFAULTS[MINIKUBE_BIN]=${DEFAULTS[MINIKUBE_HOME]}/bin
DEFAULTS[MINIKUBE_VERSION]=0.34.1
DEFAULTS[KVM_DRIVER_VERSION]=0.31.0
DEFAULTS[KUBEVIRT_VERSION]=0.14.0
DEFAULTS[KUBECONFIG]=${DEFAULTS[MINIKUBE_HOME]}/kubeconfig
DEFAULTS[VIRT_EMULATION]=true

function usage() {
   echo "usage: $0 [options]
 -c               - CLEANUP - remove old stuff
 -d               - DEBUG - debug output
 -h               - help: print this message
 -H <directory>   - MINIKUBE_HOME - Where the .minikube cache directory is
 -B <directory>   - MINIKUBE_BIN  - Where the minikube binaries will be
 -m <version>     - MINIKUBE_VERSION
 -M <version>     - KVM_DRIVER_VERSION (defaults to MINIKUBE_VERSION)
 -k <version>     - KUBEVIRT_VERSION
 -C <file>        - KUBECONFIG    - The kubeconfig file
 -v               - VERBOSE - informative output
 -V               - VIRT_EMULATION
"
}

function process_args() {
    while getopts "cdhvVH:B:m:M:k:C:" opt; do
        case $opt in
            H )
                MINIKUBE_HOME=$OPTARG
                ;;
            B )
                MINIKUBE_BIN=$OPTARG
                ;;
            m )
                MINIKUBE_VERSION=$OPTARG
                ;;
            M )
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
            V ) VIRT_EMULATION='true'
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

        # defaults to MINIKUBE_VERSION if not provided
        [ -z ${KVM_DRIVER_VERSION+x} ] && KVM_DRIVER_VERSION=${MINIKUBE_VERSION}
    done
}

function verbose_args() {
    echo "--- ARGS ---"
    echo "MINIKUBE_HOME=${MINIKUBE_HOME}"
    echo "MINIKUBE_BIN=${MINIKUBE_BIN}"
    echo "MINIKUBE_VERSION=${MINIKUBE_VERSION}"
    echo "KVM_DRIVER_VERSION=${KVM_DRIVER_VERSION}"
    echo "KUBEVIRT_VERSION=${KUBEVIRT_VERSION}"
    echo "KUBECONFIG=${KUBECONFIG}"
    echo "------------"
}

function report_environment() {
    echo
    echo "--- BEGIN configuration information ---"
    echo PATH = ${PATH}
    echo
    minikube version
    echo "";
    echo "OS:";
    cat /etc/os-release
    echo "";
    if [ -f ${MINIKUBE_HOME}/.minikube/machines/minikube/config.js ] ; then
        echo "VM driver:"; 
        grep DriverName ${MINIKUBE_HOME}/.minikube/machines/minikube/config.json
        echo "";
        echo "ISO version";
        grep -i ISO ${MINIKUBE_HOME}/.minikube/machines/minikube/config.json
    else
        echo "No Minikube Configuration Found"
    fi
    echo "--- END configuration information ---"
    echo
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
    KUBECTL=${MINIKUBE_BIN}/kubectl
    MINIKUBE=${MINIKUBE_BIN}/minikube
    KVM_DRIVER=${MINIKUBE_BIN}/docker-machine-driver-kvm2
    VIRTCTL=${MINIKUBE_BIN}/virtctl
}

function create_working_directories() {
    [ -d ${MINIKUBE_BIN} ] || mkdir -p ${MINIKUBE_BIN}
    [ -d ${MINIKUBE_HOME} ] || mkdir -p ${MINIKUBE_HOME}
}

function cleanup_old_runs() {
    rm -f ${MINIKUBE_BIN}/{minikube,docker-machine-driver-kvm2,virtctl,kubectl}
    rm -rf ${MINIKUBE_HOME}/.minikube
    rm -f ${KUBECONFIG}
}

function cleanup_kvm_instance() {
    virsh --connect qemu:///system destroy minikube
    virsh --connect qemu:///system undefine minikube
}

# ===========================================================================
# Prerequisite Tests
# ===========================================================================

# libvirtd present and running, accessable

# docker present, running, accessable

# nested virt enabled

# ===========================================================================
# Installation Functions
# ===========================================================================

function install_kubectl() {
    curl --silent -L -o ${KUBECTL} https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod a+x ${KUBECTL}
}

function install_minikube() {
    curl --silent -L -o ${MINIKUBE} https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-linux-amd64
    chmod a+x ${MINIKUBE}
}

function install_kvm_driver() {
    curl --silent -L -o ${KVM_DRIVER} https://storage.googleapis.com/minikube/releases/v${KVM_DRIVER_VERSION}/docker-machine-driver-kvm2
    chmod a+x ${KVM_DRIVER}
}

function install_virtctl() {
    curl --silent -L -o ${VIRTCTL} https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/virtctl-v${KUBEVIRT_VERSION}-linux-amd64
    chmod a+x ${VIRTCTL}
}

function start_minikube() {
    verbose "-- starting minikube"
    local minikube_args="--vm-driver kvm2 --network-plugin cni --enable-default-cni --feature-gates=DevicePlugins=true --memory 4096"

    ${MINIKUBE} start ${minikube_args}
}

function enable_nested_virt_emulation() {
    ${KUBECTL} create configmap -n kubevirt kubevirt-config --from-literal debug.useEmulation=true
}

function install_kubevirt() {
    local version=$1
    ${KUBECTL} apply -f https://github.com/kubevirt/kubevirt/releases/download/v${version}/kubevirt-operator.yaml
    enable_nested_virt_emulation
    ${KUBECTL} apply -f https://github.com/kubevirt/kubevirt/releases/download/v${version}/kubevirt-cr.yaml
}

# ----------------------------------------------------------------------------
# POD STATUS FUNCTIONS
# ----------------------------------------------------------------------------
#
# The list of pods in startup order
#
declare -a PODNAMES=(
    coredns-
    kube-proxy-
    storage-provisioner
    kube-apiserver-minikube
    etcd-minikube
    kube-scheduler-minikube
    kube-addon-manager-minikube
    kube-controller-manager-minikube
)

# 
# The number of each pod that should be running
#   assoc array keys are not ordered :-(
#
declare -A PODCOUNTS=(
    [coredns-]=2
    [kube-proxy-]=1
    [storage-provisioner]=1
    [kube-apiserver-minikube]=1
    [etcd-minikube]=1
    [kube-scheduler-minikube]=1
    [kube-addon-manager-minikube]=1
    [kube-controller-manager-minikube]=1
)

# 
# Count the pods with the given name and status == "Running"
#
function num_running_pods() {
    local _name_re=$1

    local _query="[
                    .items[] |
                      select(.metadata.name | match(\"(^${_name_re}.*)\"))
                      .status.phase==\"Running\"
                  ] | length"
    kubectl get pods --namespace kube-system -o json | jq "$_query"
}

#
# check that each pod has the minimum number of running instances
#
function all_system_pods_running() {
    for PODNAME in "${PODNAMES[@]}" ; do
        [ $(num_running_pods $PODNAME) -ge "${PODCOUNTS[$PODNAME]}" ] || return 1
    done
    return 0
}

#
# Test all of the pod names for the minimum count until all are up
#
function wait_for_system_pods() {
    local _poll_interval=5 # seconds
    local _polls_max=24    # 2 minutes
    local _tries=0

    verbose waiting for system pods
    while ! all_system_pods_running && [ $_tries -lt $_polls_max ] ; do
        sleep $_poll_interval
        _tries=$(($_tries + 1))
        verbose pod test: $_tries tries
    done

    # true if all pods are up before the poll_max is reached
    [ $_tries -lt $_polls_max ]
}

# ----------------------------------------------------------------------------
# Additional Service Pod Installation
# ----------------------------------------------------------------------------

# minikube iso:
#      --iso-url string                    Location of the minikube iso (default "https://storage.googleapis.com/minikube/iso/minikube-v0.33.1.iso")

#start_minikube

# https://kubernetes.io/docs/setup/independent/troubleshooting-kubeadm/
# https://kubernetes.io/docs/concepts/cluster-administration/addons/
#  Network plugins
# Weave
# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/
# Flannel
# https://github.com/coreos/flannel/blob/master/Documentation/kubernetes.md
#
# CNI plugins:
# https://github.com/containernetworking/plugins

function initialize_network_plugin() {
    ${KUBECTL} apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

function cleanup() {
    minikube delete
    [ -d ${MINIKUBE_HOME}/.minikube ] && rm -rf ${MINIKUBE_HOME}/.minikube
    cleanup_old_runs
    cleanup_kvm_instance
}
# =============================================================================
#  MAIN
# =============================================================================
process_args $@
apply_defaults

[ -z "${VERBOSE+x}" ] || verbose_args

if [ ! -z "${CLEANUP+x}" ] ; then
    cleanup
    exit
fi

define_file_locations

create_working_directories

install_kubectl
install_minikube
install_kvm_driver
install_virtctl

start_minikube

[ -z "${DEBUG+x}" ] || report_environment

wait_for_system_pods || (echo "pods did not start in time" && exit 2)

initialize_network_plugin

install_kubevirt ${KUBEVIRT_VERSION}
verbose && echo "INITIALIZED minikube v${MINIKUBE_VERSION}, kubevirt v${KUBEVIRT_VERSION}"
