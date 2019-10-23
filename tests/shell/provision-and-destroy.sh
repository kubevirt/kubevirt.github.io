#!/usr/bin/env bash

#####
## Purpose: Testing basic ability to deploy _any_ sort of VM from the expected image.
#####

echo '-----------------------'
echo "Beginning Basic Provisioning Test on ${targetEnvironment}"
echo '-----------------------'

echo $targetEnvironment | egrep '^(aws|gcp|minikube)' >/dev/null
if [[ $? -ne 0 ]]; then
  echo "Unknown environment given: ${targetEnvironment}." >&2
  echo "Exiting with an error." >&2
  exit 1
fi

# Ansible playbooks are in the prior folder, launch from there
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR}
cd ..

ansible-playbook ansible/${targetEnvironment}-provision.yml && ansible-playbook ansible/${targetEnvironment}-cleanup.yml
