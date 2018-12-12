#!/bin/bash

#
# Push a demo test to a remote host with kubevirt installed
# Push the run_script.py script to the remote host
# Execute the demo test on the remote host
#

# =============================================================================
# Define Arguments and defaults
# =============================================================================

declare -A DEFAULTS

DEFAULTS[REMOTE_USERNAME]=centos
DEFAULTS[RUN_DEMO_SCRIPT]="~/kubevirt.github.io/scripts/run_script.py"
DEFAULTS[DEBUG_SCRIPT]=""
DEFAULTS[DEMO_ROOT]="~/kubevirt.github.io/_includes/scriptlets"

function usage() {
   echo "usage: $0 [options]
 -D                           - debug the remote script
 -N [demo name]               - the name of the demo to run
 -R [kubevirt.github.io root] - root location for script and demos
                                [default: ~/kubevirt.github.io]
 -S [run_script]              - specify the run script
                                [default: run_script.py]
 -U [remote username]         - specify the remote user [default: centos]
   
"
}

function process_args() {
    while getopts "DH:R:S:U:" opt; do
        case $opt in
            D )
                DEBUG_SCRIPT="-d"
                ;;
            H )
                REMOTE_HOSTNAME=${OPTARG}
                ;;
            N )
                DEMO_DIR=${OPTARG}
                ;;
            S )
                RUN_DEMO_SCRIPT=${OPTARG}
                ;;
            U )
                REMOTE_USERNAME=$OPTARG
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


# =============================================================================
# MAIN
# =============================================================================

# Check if the run script is a file
if [ ! -r ${DEMO_NAME} ] ; then
    # compose the demo path from defaults
fi

DEMO_DIR=$2
RUN_SCRIPT=$3

#
# Define SSH and SCP command parameters
#
SSH_OPTIONS="-o StrictHostKeyChecking=no"
SSH="ssh ${SSH_OPTIONS}"
SCP="scp ${SSH_OPTIONS}"

#
# Where to send commands
#
TESTHOST=${REMOTE_USERNAME}@${REMOTE_HOSTNAME}

# Create remote directories (if needed)
${SSH} ${TESTHOST} mkdir -p bin demos

# Copy the run script file to the remote bin and make it executable
${SCP} ${RUN_SCRIPT} ${TESTHOST}:bin
${SSH} ${TESTHOST} chmod a+x bin/\*

# Copy the desired demo test to the remote host
${SCP} -r ${DEMO_DIR}/ ${TESTHOST}:demos/

# Create the kubectl default config directory and link the admin.conf if needed
${SSH} ${TESTHOST} 'mkdir -p ~/.kube ; [ -r ./admin.conf -a ! -r .kube/config ] && ln -s ~/admin.conf .kube/config'

# Get the name of the demo from the path
DEMO_NAME=$(basename ${DEMO_DIR})

# Execute the demo on the remote host
${SSH} ${TESTHOST} bin/run_script.py -t demos/${DEMO_NAME} -d
