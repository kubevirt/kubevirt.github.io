---
layout: post
author: Pablo Iranzo Gómez
description: Jenkins CI server upgrade and jobs for KubeVirt labs and image creation refresh
title: Jenkins Infra upgrade
navbar_active: Blogs
pub-date: Nov 22
pub-year: 2019
category: news
---

## Introduction

In the article [Jenkins Jobs for KubeVirt Lab Validation]({% post_url 2019-10-31-jenkins-jobs-for-kubevirt-lab-validation %}) we did cover how Jenkins did get the information about the labs and jobs to perform.

In this article, we'll cover the configuration changes in both Jenkins and the JenkinsFiles in order to get our CI setup updated to lastest Jenkins and plugins versions as of this writing.

## Jenkins

Our Jenkins instance, is running on top of [CentOS OpenShift](https://console.apps.ci.centos.org:8443/console/) and is one of the OS-enhanced Jenkins instances, that provide persistent storage and other pieces bundled.

Jenkins was already complaining of having lot of updates pending (security, engine, etc), but the `jenkins.war` was embedded in the container image we were using.

Initial attempts tried to use environment variables to override the WAR to use, but our image was not prepared for it, so we were given the option to just generate a new container for it.

This however, seemed a bad approach as our image also contained custom libraries (`contra-lib`) that allowed to communicate with OpenShift to run the tests inside containers there.

Finally, as we're using a persistent `/var/lib/jenkins` folder, it was noticed that it contained a `war` folder which contained the unarchived `jenkins.war`.

Manually downloading latest `jenkins.war`, and unzipping it on that folder, allowed us to upgrade Jenkins code.

## The plugins

After upgrading the Jenkins core, we could use the internal plugin manager to upgrade all the remaining plugins, however, that meant a big change in the plugins, configurations, etc.

After initially being able to run the lab validations for a while, on next morning we wanted to release a new image (from Cloud-Image-Builder) and it failed to build because of the external libraries, and also affected the lab validations again.

At this point, it was decided to go forward with the full upgrade: latest stable jenkins, latest available plugins and reconfigure what was changed.

### OpenShift Plugin

Updated to configure the instance of CentOS OpenShift with the system account for accessing it:

![Jenkins OpenShift Client configuration](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-09-44-56.png)


### OpenShift Jenkins Sync
Updated and configured to use the console as well with `kubevirt` namespace:
![Jenkins OpenShift sync configuration](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-09-46-47.png)

### Global Pipeline Libraries

Here we added the libraries we used, but targetting latest version in `master` branch.

- contra-lib: <https://github.com/openshift/contra-lib.git>
- cico-pipeline-library: <https://github.com/CentOS/cico-pipeline-library.git>
- contra-library: <https://github.com/CentOS-PaaS-SIG/contra-env-sample-project>

For all of them, we ticked:

- `Load Implicitly`
- `Allow default version to be overriden`
- `Include @Library changes in job recent changes`

Jenkins replied with the 'currently maps to revision: `hash`' for each one of them, after having loaded them properly.

### Slack plugin

In addition to regular plugins used for builds, we incorporated the slack plugin to validate the notifications of build status to a test slack channel. Configuration is really easy, from within Slack, when added the jenkins notifications plugin, a `token` is provided that must be configured in Jenkins as well as a default `room` to send notifications to.

### Kubernetes 'Cloud'

In addition Kubernets `Cloud` was configured pointing to the same console access and using the `kubevirt` namespace:

![OpenShift Cloud definition and URL and tunnel settings](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-09-51-19.png)

The libraries we added, automatically add some pod templates for `jenkins-contra-slave`:

![Jenkins-contra-slave container configuration](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-09-54-24.png)

## Other changes

Our environment also used other helper tools as regular OpenShift builds:

![OpenShift Build repositories and status](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-09-55-41.png)

We had to update the repos from using some of the older ones (no longer valid and outdated) to use latest versions, and for the ansible-executor we also created a fork to use the newest libraries for accessing Google Cloud environment and tuning some of the other variables (<https://github.com/CentOS-PaaS-SIG/contra-env-infra/pull/59>).

The PR has been closed as in parallel another change landed in the repository that also included our proposed changes.

The issue that we were facing was related with the failure to write temporary files to the $HOME folder for the user so ansible configuration was forced to use one in a temporary and writable folder.

Additionally, Google Cloud access required updating libraries for authentication that were failing as well.

## Job Changes

Our Jenkins Jobs were defined (as documented in prior article) inside each repository that made that part easy on one side, but also required some tuning and changes:

- We have disabled minikube validation as it was failing for both AWS and GCP unless using baremetal (so we're wondering about using another approach here)
- We've added code to do the actual 'Slack' notification we mentioned above
- Extend the try/catch block to include a 'finally' to send the notifications
- Change the syntax for 'artifacts' as it was previously `ArchiveArtifacts` and now it's a `postBuild`


## The outcome

After several attempts:

![Sunny build status](/assets/2019-11-22-jenkins-ci-server-upgrade-and-jobs-for-kubevirt/2019-11-11-11-02-34.png)

Of course, one of the advantages is that builds happen automatically everyday or on code changes on the repos.

There's still room for improvement identified that will happen in next iterations:
- Find running instances on Cloud providers to shutdown for reducing the bills
- Trigger builds when new releases of kubevirt happen (out of kubevirt/kubevirt repo)
- Unify testing on [Prow instance]({% post_url 2019-10-31-prow-jobs-for-kubevirt %})
