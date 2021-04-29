# KubeVirt.io Website

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

## Contributing contents

We gladly welcome contributions to the KubeVirt website. Please reach out if you happen to have an idea or find an issue with our contents! [Here's our guidelines for contents](GUIDELINES.md).


## Get Started

### Make changes to Your fork

The KubeVirt.io website is a Jekyll site, hosted with GitHub Pages.

You can find the markdown that power the site under `./pages`.
Each section of the site is broken out into their respective folders.

* `./blogs` for the various Blog pages.
* `./docs` for the Documentation.
* `./videos` for the videos that are shared.

All site images are located under `./assets/images`. Please do not edit these images.

Images that relate to blog entries are located under `./assets/images/BLOG_POST_TITLE`.  
The **BLOG_POST_TITLE** should match the name of the markdown file that you added under `/_posts`.


#### sign your commits

Signature verification on commits are required -- you may sign your commits by running:

```console
$ git commit -s -m "The commit message" file1 file 2 ...
```

Signed commit messages generally take the following form:

```
<your commit message>

Signed-off-by: <your configured git identity>
```

## Test your changes in a local container


```bash
$ make run
```

**NOTE** If you use `docker` you may need to set `CONTAINER_ENGINE` and `BUILD_ENGINE`:

```console
$ export CONTAINER_ENGINE=docker
$ export BUILD_ENGINE=docker
$ make run
```

**NOTE** If you are in an SELinux enabled OS you need to set `SELINUX_ENABLED`:

```console
$ export SELINUX_ENABLED=True
```

Open your web browser to http://0.0.0.0:4000 and validate page rendering

### Create a pull request to `kubevirt/kubevirt.github.io`

After you have vetted your changes, `kubevirt/kubevirt.github.io` so that others can review.

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
  check_links         	 Check external, internal links and links/selectors to userguide on website content
  check_spelling      	 Check spelling on content
  build_image_casperjs	 Build image: casperjs
  build_image_yaspeller	 Build image: yaspeller
  run                 	 Run site.  App available @ http://0.0.0.0:4000
  status              	 Container status
  stop                	 Stop site
  stop_casperjs       	 Stop casperjs image
  stop_yaspeller      	 Stop yaspeller image

```
### Environment Variables

* `CONTAINER_ENGINE`: Some of us use `docker`. Some of us use `podman` (default: `podman`).
* `BUILD_ENGINE`:	Some of us use `docker`. Some of us use `podman` (default: `podman`).
* `SELINUX_ENABLED`:	Some of us run SELinux enabled. Set to `True` to enable container mount labelling.


### Targets:

* `check_links`: HTMLProofer is used to check any links to external websites as we as any cross-page links.
* `check_spelling`: yaspeller is used to check spelling. Feel free to update to the dictionary file as needed (kubevirt/project-infra/images/yaspeller/.yaspeller.json).
* `build_image_casperjs`: casperjs project does not provide a container image.  Use this target to build an image packed with with nodejs. casperjs will verify all site links in `/_site`.
* 'build_image_yaspeller': yaspeller project does not provide a container image.  User this target to Build an image packed with nodejs and yaspeller app. yaspeller will check content for spelling and other bad forms of English.
* `status`: Basically `${BUILD_ENGINE} ps` for an easy way to see what's running.
* `stop`: Stop container and app
* `stop_yaspeller`: Sometimes yaspeller goes bonkers.  Stop it here.



## Getting Help

* Slack: https://kubernetes.slack.com/messages/virtualization
* Twitter: https://twitter.com/kubevirt


## Developer

* Github Projects: https://github.com/kubevirt
* Community meetings: [Google Calendar](https://calendar.google.com/calendar/embed?src=18pc0jur01k8f2cccvn5j04j1g%40group.calendar.google.com&ctz=Etc%2FGMT)

## Privacy

* Check our privacy policy at: https://kubevirt.io/privacy/
