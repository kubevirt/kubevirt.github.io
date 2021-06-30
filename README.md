# Contributing to KubeVirt.io

[![Build Status](https://prow.ci.kubevirt.io/badge.svg?jobs=push-kubevirt.github.io-master-build-and-push-to-gh-pages)](https://prow.ci.kubevirt.io/?repo=kubevirt%2Fkubevirt.github.io&type=postsubmit&job=push-kubevirt.github.io-master-build-and-push-to-gh-pages)

The [kubevirt.io](https://kubevirt.io) website is a [Jekyll](https://jekyllrb.com/) driven site hosted by GitHub Pages.

Contributions to the KubeVirt website are very much welcomed! Please reach out with ideas for new content or issues with existing content!

## Getting Started

### Git semantics

A semi standard process is followed to move code from development to production.

The basic process is ...

```bash
Fork -> Clone -> Branch -> Commit -> Push -> Pull Request -> Approve -> Merge
```

#### Fork

Create a forked copy of the repository to your  account by pressing the `Fork` button at the top of the repository page. This should be the only time a fork needs to be created as long as the fork is properly maintained by performing branch sync and rebase with upstream periodically.


#### Clone

To clone the forked repository locally, browse to your fork at https://www.github.com/*github_name*/kubevirt.github.io. Click the `Code` button. Select a clone method and copy the url to clipboard. Open a terminal window and  ...

```bash
git clone *clipboard paste url*
```

#### Remotes

By default the local git repo will have a remote alias called `origin` that points to your fork in GitHub. KubeVirt repositories have many contributors so work needs to be done periodically to synchronize local and origin branches with upstream branches. To enable this work flow on your local clone, add a new remote to the repository. By convention, this remote is named `upstream`.

To add an additional remote perform the following command...

```bash
git remote add upstream http/ssh url
```

And then you should see something like...

```bash
$ git remote -v
origin	git@github.com:mazzystr/kubevirt.github.io.git (fetch)
origin	git@github.com:mazzystr/kubevirt.github.io.git (push)
upstream	git@github.com:kubevirt/kubevirt.github.io.git (fetch)
upstream	git@github.com:kubevirt/kubevirt.github.io.git (push)
```

To sync the master branch from the upstream repository, perform the following ...

```bash
git checkout master; git fetch upstream; git reset --hard upstream/master; git push origin master -f
```

*Note* Master branch is purely cosmetic for this repo. Merges to master **ARE NOT ACCEPTED**.


All work must be branched from `maaster` branch. Perform the following to sync from upstream ...

```bash
git checkout master; git fetch upstream; git reset --hard upstream/master; git push origin master -f
```

#### Feature branch

Even though changes from a local `master` branch are accepted it is inadvisable, can cause confusion and possibly data loss. Please use feature branches branched from `master` by running the following ...

```bash
git checkout master; git fetch upstream; git reset --hard upstream/master; git push origin master -f; git branch feat_branch; git checkout feat_branch; git push --set-upstream origin feat_branch
```

#### Rebase

Periodically a feature branch will need to be rebased as the local and origin fall behind upstream. Perform the following to rebase ...

```bash
git checkout master; git fetch upstream; git reset --hard upstream/master; git push origin master -f; git checkout feat_branch; git rebase origin/master; git push -f
```

There is always a strong possibility for merge conflicts. Proceed with caution in resolving. Each conflict must be hand edited. Perform the following to resolve each conflict ...

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


## Test work

The Makefile at the base of this repository provides editors the ability to locally run the same tests CI uses to validate changes. This saves time over waiting for online CI resources to spin up just to find out a pull request has a problem that prevents merge.

1) Build the test image locally
```bash
$ make build_img
```

**NOTE** If you use `docker` you may need to set `CONTAINER_ENGINE` and `BUILD_ENGINE`:

```bash
$ export CONTAINER_ENGINE=docker
$ export BUILD_ENGINE=docker
```

**NOTE** If you are in an SELinux enabled OS you need to set `SELINUX_ENABLED`:

```bash
$ export SELINUX_ENABLED=True
```

2) Validate page rendering
```bash
make run
```
Open your web browser to http://0.0.0.0:4000

3) Test all hyperlinks
```bash
make test_links
```

4) Test spelling
```bash
make test_spelling
```

If you discover a flagged spelling error that you believe is not a mistake, feel free to add the offending word to the dictionary file located at GitHub repo `kubevirt/project-infra/images/yaspeller/.yaspeller.json`. Try to keep the dictionary file well ordered and employ regular expressions to handle common patterns.

#### Make sure all tests pass before committing!

#### Submitting your code

1) Commit your code and sign your commits!
```bash
git commit -s -m "The commit message" file1 file 2 file3 ...
```

**Signature verification on commits are required! No exceptions!**

You will see the following in the transaction log
```bash
git log
commit hashbrowns (HEAD -> feat_branch, upstream/master, origin/master, master)
Author: KubeVirt contributer <kubevirt_contributer@kubevirt.io>
Date:   Mon Jan 01 00:00:00 2021 -0700

<your commit message>

Signed-off-by: <your configured git identity>
```

2) Browse to `https://www.github.com/*you*/kubevirt.github.io`

3) Often you will see a `Compare & Pull Request` button ... Click on that

4) Ensure your base branch is `master`, your compare branch is `feat_branch`, and the file diff's are correct.

5) Create a nice subject and body for the pull request. Be sure to tag related issues, people of interest, and click the "Create pull request" button.

**Maintainers will automatically be notified a pull request has been created and will give further instruction on getting contribution merged.**


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
