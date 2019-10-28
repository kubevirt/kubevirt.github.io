#!/usr/bin/env bash

#########################################
### Global Vars and Utility Functions
#########################################

## This disables a warning about something that's intended behavior (not having inventory for provisioning and cleanup
export ANSIBLE_LOCALHOST_WARNING="False"

## Default to running lab1 tests
if [[ -z "$1" ]]; then

  labName="lab1"

else

  labName="$1"

fi

failImmediately(){
  if [[ $1 -ne 0 ]]; then
    echo "Ansible Playbook $2 Failed with: $1" >&1
    exit $1
  fi
}


#########################################
### Main Logic
#########################################

echo '-----------------------'
echo "Beginning Test for ${labName} on ${targetEnvironment}"
echo '-----------------------'

echo $targetEnvironment | egrep '^(aws|gcp|minikube)' >/dev/null

if [[ $? -ne 0 ]]; then

  echo "Unknown environment given: ${targetEnvironment}." >&2
  echo "Exiting with an error." >&2
  exit 1

fi

# Ansible playbooks are in the prior folder, launch from there
cd $(dirname "${BASH_SOURCE[0]}")/..

echo Lab ${labName} Provision
echo ${SSH_KEY_LOCATION}
set -o pipefail
ansible-playbook --private-key ${SSH_KEY_LOCATION} ansible/${targetEnvironment}-provision.yml | tee ansible-${targetEnvironment}-${labName}-provision.log
failImmediately $? Provision

echo Lab ${labName} Validation
ansible-playbook --private-key ${SSH_KEY_LOCATION} -i /tmp/inventory ansible/${labName}.yml | tee ansible-${targetEnvironment}-${labName}.log
failImmediately $? Validation

echo Lab ${labName} Cleanup
ansible-playbook --private-key ${SSH_KEY_LOCATION} ansible/${targetEnvironment}-cleanup.yml | tee ansible-${targetEnvironment}-${labName}-cleanup.log
failImmediately $? Cleanup
