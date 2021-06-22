# Contributing to KubeVirt.io

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

The [kubevirt.io](https://kubevirt.io) website is a [Jekyll](https://jekyllrb.com/) driven site hosted by GitHub Pages.

Contributions to the KubeVirt website are very much welcomed! Please reach out with ideas for new content or issues with existing content!

## Getting Started

### Git workflow

A semi standard process is followed to move code from development to production.

The basic process is ...

```bash
Fork -> Clone -> Branch -> Work -> Test -> Commit & Push -> Pull Request -> Approve & Merge
```

#### Fork

Create a forked copy of the repository to your  account by pressing the `Fork` button at the top of the repository page. This should be the only time a fork needs to be created as long as the fork is properly maintained by performing branch sync and rebase with upstream periodically.


#### Clone

To clone the forked repository locally, browse to your fork at https://www.github.com/*github_name*/kubevirt.github.io. Click the `Code` button. Select a clone method and copy the url to clipboard. Open a terminal window and  ...

```bash
git clone *clipboard paste url*
```

| :exclamation: Be sure to set up the remotes! |
| - |

By default the local repo will have a remote alias called `origin` that points to your fork in GitHub. KubeVirt project repositories have many contributors so work needs to be done periodically to synchronize local and origin branches with branches from the main repo of the project. To enable this work flow on your local clone, add a new remote to the repository. By convention, this remote is named `upstream`.

To add an additional remote perform the following command ...

```bash
git remote add upstream <url>
```

To view the remotes perform the following command ...

```bash
$ git remote -v
origin	git@github.com:github_name/kubevirt.github.io.git (fetch)
origin	git@github.com:github_name/kubevirt.github.io.git (push)
upstream	git@github.com:kubevirt/kubevirt.github.io.git (fetch)
upstream	git@github.com:kubevirt/kubevirt.github.io.git (push)
```

To sync the master branch from the upstream repository, perform the following ...

```bash
git checkout master; git fetch upstream; git reset --hard upstream/master; git push origin master -f
```

#### Branch

All work is encouraged to be conducted within a feature branch. The feature branch must be created against branch `source` ... at this time (we're working as we speak to resolve this problem).

Perform the following to create a feature branch ...

```bash
git checkout source; git fetch upstream; git reset --hard upstream/source; git push origin source -f; git branch feature_branch; git checkout feature_branch; git push --set-upstream origin feature_branch
```

| :no_entry: Master branch is purely cosmetic for kubevirt/kubevirt.github.io. Merges to master branch ARE NOT ACCEPTED. |
| - |

<br>

Periodically a feature branch will need to be rebased. This is the term used to insert commits and logs into the current branch log to prevent conflicts when merging code with upstream.

Perform the following to rebase ...

```bash
git checkout source; git fetch upstream; git reset --hard upstream/source; git push origin source -f; git checkout feature_branch; git rebase origin/source; git push -f
```

| :warning: There is always a strong possibility for merge conflicts when performing a rebase. Each conflict must be hand edited and resolved before proceeding. |
| - |

Perform the following to resolve each conflict ...

```bash
# Modify and save the filename
git add filename; git rebase --continue
```

#### Work

[Here is our guidelines for content contribution](GUIDELINES.md).

Each section of the site is broken out into their respective folders.

* `./pages` : website
* `./blogs` : blog posts
* `./docs` : documentation.
* `./videos` : videos

All site images are located under `./assets/images`. Please do not edit these images.

Markdown for blog posts are located under `./posts`. Please follow the existing filename scheme.

Images related to blog entries get placed under `./assets/images/BLOG_POST_TITLE`.
The **BLOG_POST_TITLE** should match the name of the markdown file created under `/_posts`.

If you are a UI/UX developer, the structure and layout of the website would greatly benefit from your attention. Feel free to browse [website issues](https://github.com/kubevirt/kubevirt.github.io/issues?q=is%3Aopen+is%3Aissue+label%3Akind%2Fwebsite) or contribute other ideas.

#### Test work

This repository employs CI to test and validate proposed changes to the website. The CI process can be slow and may need to run multiple times before a change is ready for human review. To speed up this process, a Makefile is provided to run the same CI tests locally.

1) Build the container image locally
```bash
$ make build_img
```

| :warning: If you use `docker` user-space tool and runtime you may need to set `CONTAINER_ENGINE` and `BUILD_ENGINE` |
| - |
| ```$ export CONTAINER_ENGINE=docker```</p><p>```$ export BUILD_ENGINE=docker```</p> |

| :warning: If you are in an SELinux enabled OS you need to set `SELINUX_ENABLED` |
| - |
| ```$ export SELINUX_ENABLED=True``` |

2) Validate page rendering
```bash
make run
```
Open your web browser to http://0.0.0.0:4000

3) Test hyperlinks
```bash
make test_links
```

4) Test spelling
```bash
make test_spelling
```

If you discover a flagged spelling error that you believe is not a mistake, feel free to add the offending word to the dictionary file located at GitHub repo `kubevirt/project-infra/images/yaspeller/.yaspeller.json`. Try to keep the dictionary file well ordered and employ regular expressions to handle common patterns.

| :no_entry: Make sure all tests pass before committing! |
| - |

#### Commit & Push

1) Sign and commit your code!

```bash
git commit -s -m "The commit message" file1 file 2 file3 ...
```

| :no_entry: Signature verification on commits is strictly enforced! |
| - |

You will see the following in the transaction log

```bash
git log
commit hashbrowns (HEAD -> feature_branch, upstream/source, origin/source, source)
Author: KubeVirt Contributor <kubevirt_contributor@kubevirt.io>
Date:   Mon Jan 01 00:00:00 2021 -0700

<your commit message>

Signed-off-by: <your configured git identity>
```

2) Push the branch to the origin remote

```bash
$ git push origin
```

#### Pull request

1) Browse to `https://www.github.com/*github_name*/kubevirt.github.io`

2) Often you will see a `Compare & Pull Request` button ... Click on that

3) The base branch must be set to `source`. The compare branch should be the `feature_branch`. Take a look at the file diff's and ensure they are correct.

4) Create a nice subject and body for the pull request. Be sure to tag related issues, people of interest, and then click the `Create pull request` button.

| :warning: CI continuously monitors the repository for changes. When a change is detected a series of jobs will trigger to validate the code of the pull request. Please monitor them and ensure they successfully complete. Maintainers and/or other contributors may request changes before proceeding to approve and merge. |
| - |

#### Approve & Merge

The maintainers will add comments `/lgtm` and `/approve` to the pull request. Once again CI runs a job that monitors the comments section for key words. When the tags are detected the merge job will trigger and run.

The merge job performs the following functions ...
* Code from the feature branch is merged to `source` branch
* Code from `source` branch is checked out
* Code is compiled
* Code is merged to master branch
* GitHub serves code from `master` branch per Github Pages settings

## Makefile Help

```console
$ make help

Makefile for website jekyll application

Usage:
  make <target>

Env Variables:
  CONTAINER_ENGINE	Set container engine, [*podman*, docker]
  BUILD_ENGINE		Set build engine, [*podman*, buildah, docker]
  SELINUX_ENABLED	Enable SELinux on containers, [*False*, True]

Targets:
  help                	 Show help
  build_img              Build image localhost/kubevirt-kubevirt.github.io
  check_links         	 Check external, internal links and links/selectors to userguide on website content
  check_spelling      	 Check spelling on content
  run                 	 Run site. App available @ http://0.0.0.0:4000
  status              	 Container status
  stop                	 Stop site
```

### Environment Variables

* `CONTAINER_ENGINE`: Some of us use `docker`. Some of us use `podman` (default: `podman`).
* `BUILD_ENGINE`:	Some of us use `docker`. Some of us use `podman` (default: `podman`)
* `SELINUX_ENABLED`:	Some of us run SELinux enabled. Set to `True` to enable container mount labelling


### Targets:

* `build_img`: Use this target to build an image packed with Jekyll, casperjs, yaspeller and HTMLProofer.
* `check_links`: HTMLProofer is used to check any links to external websites as well as any cross-page links. Casperjs is used to dissect user-guide urls containing markdown selectors and ensure they exist.
* `check_spelling`: yaspeller is used to check spelling. Feel free to update to the dictionary file as needed (kubevirt/project-infra/images/yaspeller/.yaspeller.json).
* `status`: Basically `${BUILD_ENGINE} ps` for an easy way to see what's running.
* `stop`: Stop container and app

## Getting Help

* Mailing list: https://groups.google.com/g/kubevirt-dev
* Slack: https://kubernetes.slack.com/messages/virtualization
* Twitter: https://twitter.com/kubevirt

## Developer

* Github project: https://github.com/kubevirt
* Community meetings: [Google Calendar](https://calendar.google.com/calendar/embed?src=18pc0jur01k8f2cccvn5j04j1g%40group.calendar.google.com&ctz=Etc%2FGMT)

## Privacy

* Check our privacy policy at: https://kubevirt.io/privacy/
