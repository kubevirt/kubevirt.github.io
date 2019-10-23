# KubeVirt.io Laboratory testing

This repository contains tests for KubeVirt.io laboratories regarding the **try it!** buttons. The environments tested are GCE, AWS and Minikube (you could replace ${PROVIDER} any of them).

## Resources

- Jenkins jobs:
  - Image Generation: https://jenkins-kubevirt.apps.ci.centos.org/job/dev/job/jodavis/job/kvio-lab-testing/

## Workflow

The entry point is the Jenkinsfile which executes this pipeline:

- `shell/provision-and-destroy.sh`: This script will execute 2 ansible playbooks in a row, the first one will bootstrap an image prebuilt by [this repo](https://github.com/kubevirt/cloud-image-builder) which raise up a KubeVirt environment on a ${PROVIDER} and then when the KubeVirt environments was up and running stops it and delete it. This test will ensure that the Images are working fine and could bootstrap a well formed KubeVirt environment. The ansible playbooks executed are these:

  - `${PROVIDER}-provision.yml`
  - `${PROVIDER}-cleanup.yml`

- `sh shell/lab.sh labX`: `lab.sh` is a lab executor which accept a parameter with the `labX.yml` filename. This will wrap the lab results and the possible fails that could happen on the execution. This `labx.sh`:

  - Raises up an KubeVirt enironment with `${PROVIDER}-provision.yml`.
  - Executes the `LabX.yml` ansible manifest.
  - Deletes the previous KubeVirt enironment with `${PROVIDER}-cleanup.yml`.

- `labX.yml`: Contains the test cases in a hardcoded way, that ansible executes in the KubeVirt environment.

## Results

The test results are stored on the Jenkins environment as:

- `ansible-${targetEnvironment}-${labName}-provision.log`
- `ansible-${targetEnvironment}-${labName}.log`
- `ansible-${targetEnvironment}-${labName}-cleanup.log`


- [Build/Test log Sample](https://jenkins-kubevirt.apps.ci.centos.org/job/dev/job/jodavis/job/kvio-lab-testing/30/consoleFull)
- [Builded artifacts](https://jenkins-kubevirt.apps.ci.centos.org/job/dev/job/jodavis/job/kvio-lab-testing/lastSuccessfulBuild/artifact/), log separated by ${PROVIDER}.

## TO-DO

- Dynamic Lab testing following [**Literate Programming method with MDSH**](https://en.wikipedia.org/wiki/Literate_programming) [like we do here](https://github.com/kubevirt/kubevirt-tutorial) and is documented [here](https://github.com/RHsyseng/kubevirt-tutorial-testing-deck)
