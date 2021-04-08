---
layout: post
author: Pablo Iranzo Gómez
description: How prow is used to keep website and tutorials 'up'
title: Prow jobs for KubeVirt website and Tutorial repo
navbar_active: Blogs
pub-date: October 31
pub-year: 2019
category: news
tags:
  [
    prow,
    infrastructure,
    kubevirt-tutorial,
    CI-CD,
    continuous integration,
    community,
  ]
---

## Introduction

[Prow](https://github.com/kubernetes/test-infra/tree/master/prow) is a Kubernetes based CI/CD system that has several types of jobs and is used at KubeVirt project.

General PR's, etc are tested by Prow to be validated to be reviewed by doing some sanity checks defined by developers.

In general, the internals on how it works can be checked at [Life of a Prow Job](https://github.com/kubernetes/test-infra/blob/master/prow/life_of_a_prow_job.md), and of course in the presentation made by [Juanma](https://github.com/jparrill) on <https://talks.godoc.org/github.com/jparrill/hands-on-prow/hands-on-prow.slide#1>.

## Community repositories

There are other repos (involved in the project ecosystem) that have tests to validate the information provided on them.

The community repositories include:

- [KubeVirt website](https://github.com/kubevirt/kubevirt.github.io)
- [KubeVirt tutorial](https://github.com/kubevirt/kubevirt-tutorial)
- [Katacoda Scenarios](https://github.com/metal3-io/metal3-io.github.io)
- [Community repo](https://github.com/kubevirt/community)
- [Cloud Image Builder](https://github.com/kubevirt/cloud-image-builder)

Those repos contain useful information for new users, like the `try-it` scenarios, the Laboratories, [Katacoda scenarios](https://katacoda.com/kubevirt), Community supporting files (like logos, proposals, etc).

## The jobs

For each repo we've some types of jobs:

- `periodical`: Run automatically to validate that the repo, without further changes is still working (for example, detecting broken URL's).
- `presubmit`: Validates that the incoming PR will not break the environment.
- `post-submit`: After merging the PR, the repo is still working.

Jobs are defined in the [project-infra](https://github.com/kubevirt/project-infra/) repository, for example:

- <https://github.com/kubevirt/project-infra/blob/master/github/ci/prow-deploy/files/jobs/kubevirt/kubevirt-tutorial/kubevirt-tutorial-periodics.yaml>
- <https://github.com/kubevirt/project-infra/blob/master/github/ci/prow-deploy/files/jobs/kubevirt/kubevirt-tutorial/kubevirt-tutorial-presubmits.yaml>

Those jobs define the image to use (image and tag), and the commands to execute. In the examples above we're using 'Docker-in-Docker' (dind) images and we're targetting the KubeVirt-tutorial repository.

### KubeVirt-tutorial

The jobs, when executed as part of the Prow workflow, run the commands defined in the repo itself, for example for `kubevirt-tutorial` check the following folder:

- <https://github.com/kubevirt/kubevirt-tutorial/tree/master/hack>

That folder contains three scripts: `build`, `test_lab` and `tests`, which do setup the environment for running the validations, that is:

- install required software on top of the used images.
- prepare the scripts to be executed via [mdsh](https://github.com/bashup/mdsh) which extracts markdown from lab files to be executed against the cluster setup by Prow (using `dind`).
- Run each script and report status

Once the execution has finished, if the final status is `ok`, the status is reported back to the GitHub PR so that it can be reviewed by mantainers of the repo.

## Job status

The jobs executed and the logs are available on the Prow instance we use, for example:

- <https://KubeVirt.io>
  - Pre-submit link checker: <https://prow.apps.ovirt.org/?job=kubevirt-io-presubmit-link-checker>
  - Periodical link checker: <https://prow.apps.ovirt.org/?job=kubevirt-io-periodic-link-checker>
- [KubeVirt Tutorial](https://github.com/kubevirt/kubevirt-tutorial)
  - Pre-submit: <https://prow.apps.ovirt.org/?job=kubevirt-tutorial-presubmit-lab-testing-k8s-1.13.3>
  - Periodical: <https://prow.apps.ovirt.org/?job=periodic-kubevirt-tutorial-lab-testing>

## Wrap-up

If you find that a test should be performed to further validate the integrity and information provided, feel free to raise issues or even a PR against the `project-infra` repository so that we can get it improved!
