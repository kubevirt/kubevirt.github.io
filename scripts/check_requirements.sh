#!/bin/bash
#
# Check that the requirements for running the demos and/or labs are met on the
# reader's host system
#
# minikube: https://github.com/kubernetes/minikube/#requirements
#
# minishift: https://docs.okd.io/latest/minishift/getting-started/preparing-to-install.html

TARGET=${TARGET:-minikube}

function verbose() {
    [ -n "$VERBOSE" ] && echo "  $*"
}

# ------------------------------------------------------------------------------
# Check sudo capabilities
# ------------------------------------------------------------------------------
SUDO_COMMANDS=('ls' 'yum'  'systemctl status' 'usermod')
function check_sudo_capabilities() {
    # check each command offered
    local _commands=("$@")

    local _fullpath
    local _cmdstatus
    local _status
    local _paths=()

    echo "Checking for sudo capabilities. Requires cached credentials.  Will not prompt"
    _status=0
    for _command in "${_commands[@]}" ; do
        verbose testing ${_command}
        _fullpath=$(sudo --non-interactive --list ${_command} 2>&1)
        _cmdstatus=$?
        if [ $_cmdstatus -eq 0 ] ; then
            verbose "command full path: $_command -> $_fullpath"
            _paths+=($_fullpath)
        else
            echo "sudo ${_command}: not allowed"
            _status=$(($_status + 1))
        fi
    done

    verbose allowed: "${_paths[@]}"
    
    # return the number of denied commands
    return $_status
}

# -----------------------------------------------------------------------------
# Check for presence of kubectl(1)
#  We can't depend on which(1) or on RPMs to check
# -----------------------------------------------------------------------------
# Extract the kubectl version from the return string
kubectl_version_re='Major:\"([[:digit:]]+)\",[[:space:]]Minor:\"([[:digit:]]+)\"'
function kubectl_installed() {
    local _output
    local _status
    local _version

    # Check the presence of kubectl and collect output
    _output=$(kubectl version --client 2>&1)
    _status=$?

    # Verify that kubectl is/is not present and extract version
    case $_status in
        0)
            verbose "kubectl: Present: success"
#            if [[ "$_output" =~ Major:\"([[:digit:]]+)\",[[:space:]]Minor:\"([[:digit:]]+)\" ]] ; then
            if [[ "$_output" =~ $kubectl_version_re ]] ; then
                _version=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]})
                verbose "kubectl version: ${_version[0]}.${_version[1]}"
            else
                verbose "Cannot determine version of kubectl"
                verbose "kubectl returned:\n$_output"
            fi
            break;;
        
        1)
            if [[ "$_output" =~ "error: no configuration has been provided" ]] ; then
                verbose "kubectl: Present - link to oc from origin"
            else
                verbose "kubectl: Present - FAIL"
            fi
            break;;
        
        127)
            verbose "kubectl: Not Present"
            break;;
        
        *)
            echo "kubectl: Unknown return $_status"
            echo "kubectl output: $_output"
            break;;
    esac

    return $_status
}

oc_version_re='^oc v([0-9.]+)"'
function oc_installed() {
    local _output
    local _status
    local _version

    # Check the presence of kubectl and collect output
    _output=$(oc version 2>&1)
    _status=$?

    # Verify that kubectl is/is not present and extract version
    case $_status in
        0)
            verbose "oc: Present: success"
            if [[ "$_output" =~ $oc_version_re ]] ; then
                _version=${BASH_REMATCH[1]}
                verbose "oc version: ${_version}"
            else
                verbose "Cannot determine version of oc"
                verbose "oc returned:\n$_output"
            fi
            break;;
        
        1)
            verbose "oc: Present - FAIL"
            break;;
        
        127)
            verbose "oc: Not Present"
            break;;
        
        *)
            echo "oc: Unknown return $_status"
            echo "oc output: $_output"
            break;;
    esac

    return $_status    
}

# -----------------------------------------------------------------------------
#
# Verify virtualization
#
# -----------------------------------------------------------------------------
function has_kvm() {
    echo "checking for kvm"

    has_docker_machine_driver kvm || echo "kvm driver not present"
    has_docker_machine_driver kvm2 || echo "kvm2 driver not present"

    has_libvirt || echo "libvirt is not present or configured"
}

# ----------------------------------------------------------------------------
# 
# ----------------------------------------------------------------------------

# Check that the docker machine driver for kvm and/or kvm2 is present
function has_docker_machine_driver() {
    local _driver_version
    local _output
    local _status

    _driver_version=$1 # kvm or kvm2

    if ! [[ "$_driver_version" =~ ^kvm2?$ ]] ; then
        echo "invalid driver version requested: $_driver_version"
        echo "acceptable values: kvm|kvm2"
        return 1
    fi
    
    _output=$(docker-machine-driver-${_driver_version} 2>&1)
    _status=$?

    case $_status in
        0)
            verbose "docker-machine-driver-${_driver_version}: Present - FAIL"
            verbose "invalid docker machine driver: plugins must not run from CLI"
            #echo $_output
            return 1
            break;;

        1)
            verbose "docker-machine-driver-${_driver_version}: Present"
            verbose "found docker-machine-driver-${_driver_version}"
            return 0
            break;;

        127)
            verbose "docker-machine-driver-${_driver_version}: Not Present"
            break;;

        *)
            echo "docker-machine-driver-${_driver_version}: Unknown return $_status"
            echo "output: $_output"
            break;;
    esac

    return $_status
}


function has_libvirt_group() {
    # Does the libvirt group exist on this system
    grep -q ^libvirt /etc/group
}

function member_of_libvirt_group() {
    # is the current user a member of the libvirt group
    [[ $(id --groups --name) =~ libvirt ]]
}

function has_rpms() {
    # check that the requested RPMs are installed
    local _rpms=$*
    local _rpm

    for _rpm in $_rpms ; do
        rpm -q $_rpm --quiet || echo "missing RPM $_rpm"
    done
}

LIBVIRT_RPMS="libvirt-daemon-driver-qemu qemu-kvm"
function has_libvirt() {

    # group exists
    has_libvirt_group || echo "libvirt group not present in /etc/group"
    # user is member
    member_of_libvirt_group || echo "user $(id -u --name) is not a member of the libvirt group"
    
    # RPMs installed
    has_rpms ${LIBVIRT_RPMS} || echo "missing RPMs"
    
    # daemon running

    # lib directory exists: /var/lib/libvirt
    # run directory exists: /var/run/libvirt
}


# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------

function has_virtualbox() {
    echo "checking for Virtualbox"
}

function has_virtualization() {
    echo "checking virtualization"
    has_kvm || has_virtualbox
}


# ----------------------------------------------------------------------------
#
# ----------------------------------------------------------------------------

function check_requirements() {
    echo "Checking Requirements for ${TARGET}"

    (kubectl_installed && echo "kubectl present") || echo "kubectl is not present: status: $?"
    (oc_installed && echo "oc present") || echo "oc is not present: status: $?"
    (has_virtualization && echo "virtualization present") || echo "no virtualization present"
}

# ============================================================================
# MAIN
# ============================================================================
check_sudo_capabilities "${SUDO_COMMANDS[@]}" || echo "sudo not allowed"
check_requirements
