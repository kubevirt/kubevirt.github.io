---
layout: post
author: yuvalif
description: This post tries to unveil some of the internals of our build system, by allowing you to build natively on your host
navbar_active: Blogs
pub-date: June 07
pub-year: 2018
category: uncategorized
tags: [docker, container, build]
comments: true
---

In this post we will set up an alternative to the existing containerized build system used in KubeVirt.

A [new makefile](../assets/2018-06-07-Non-Dockerized-Build/Makefile.nocontainer) will be presented here, which you can for experimenting (if you are brave enough...)

# Why?

Current build system for KubeVirt is done inside docker. This ensures a robust and consistent build environment:

- No need to install system dependencies
- Controlled versions of these dependencies
- Agnostic of local golang environment

So, in general, **you should just use the dockerized build system**.

Still, there are some drawbacks there:

- Tool integration:
  - Since your tools are not running in the dockerized environment, they may give different outcome than the ones running in the dockerized environment
  - Invoking any of the dockerized scripts (under `hack` directory) may be inconsistent with the outside environment (e.g. file path is different than the one on your machine)
- Build time: the dockerized build has some small overheads, and some improvements are still needed to make sure that caching work properly and build is optimized
- And last, but not least, _sometimes it is just hard to resist the tinkering..._

## How?

Currently, the Makefile includes targets that address different things: building, dependencies, cluster management, testing etc. - here I tried to modify the minimum which is required for non-containerized build. Anything not related to it, should just be done using the existing Makefile.

> note "Note
> Cross compilation is not covered here (e.g. building `virtctl` for mac and windows)

### Prerequisites

Best place to look for that is in the docker file definition for the build environment: [hack/docker-builder/Dockerfile](https://github.com/kubevirt/kubevirt/blob/master/hack/builder/Dockerfile)

Note that not everything from there is needed for building, so the bare minimum on Fedora27 would be:

```sh
sudo dnf install -y git
sudo dnf install -y libvirt-devel
sudo dnf install -y golang
sudo dnf install -y docker
sudo dnf install -y qemu-img
```

_Similarly to the containerized case_, docker is still needed (e.g. all the cluster stuff is done via docker), and therefore, any docker related preparations are needed as well. This would include running docker on startup and making sure that docker commands does not need root privileges. On Fedora27 this would mean:

```sh
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
```

Now, getting the actual code could be done either via `go get` (don't forget to set the `GOPATH` environment variable):

```sh
go get -d kubevirt.io/kubevirt/...

```

Or `git clone`:

```sh
mkdir -p $GOPATH/src/kubevirt.io/ && cd $GOPATH/src/kubevirt.io/
git clone https://github.com/kubevirt/kubevirt
```

### [Makefile.nocontainer](../assets/2018-06-07-Non-Dockerized-Build/Makefile.nocontainer)

```makefile
all: build

bootstrap:
    go get -u github.com/onsi/ginkgo/ginkgo
    go get -u mvdan.cc/sh/cmd/shfmt
    go get -u -d k8s.io/code-generator/cmd/deepcopy-gen
    go get -u -d k8s.io/code-generator/cmd/defaulter-gen
    go get -u -d k8s.io/code-generator/cmd/openapi-gen
    cd ${GOPATH}/src/k8s.io/code-generator/cmd/deepcopy-gen && git checkout release-1.9 && go install
    cd ${GOPATH}/src/k8s.io/code-generator/cmd/defaulter-gen && git checkout release-1.9 && go install
    cd ${GOPATH}/src/k8s.io/code-generator/cmd/openapi-gen && git checkout release-1.9 && go install

generate:
    ./hack/generate.sh

apidocs: generate
    ./hack/gen-swagger-doc/gen-swagger-docs.sh v1 html

build: check
    go install -v ./cmd/... ./pkg/...
    ./hack/copy-cmd.sh

test: build
    go test -v -cover ./pkg/...

check:
    ./hack/check.sh

OUT_DIR=./_out
TESTS_OUT_DIR=${OUT_DIR}/tests

functest: build
    go build -v ./tests/...
    ginkgo build ./tests
    mkdir -p ${TESTS_OUT_DIR}/
    mv ./tests/tests.test ${TESTS_OUT_DIR}/
    ./hack/functests.sh

cluster-sync: build
    ./hack/build-copy-artifacts.sh
    ./hack/build-manifests.sh
    ./hack/build-docker.sh build
    ./cluster/clean.sh
    ./cluster/deploy.sh

.PHONY: bootstrap generate apidocs build test check functest cluster-sync
```

### Targets

To execute any of the targets use:

```sh
make -f Makefile.nocontainer <target>
```

File has the following targets:

- **bootstrap**: this is actually part of the prerequisites, but added all golang tool dependencies here, since this is agnostic of the running platform Should be called once
  - Note that the k8s code generators use specific version
  - Note that these are not code dependencies, as they are handled by using a `vendor` directory, as well as the distclean, deps-install and deps-update targets in the [standard makefile](ttps://github.com/kubevirt/kubevirt/blob/master/Makefile)
- **generate**: Calling [hack/generate.sh](https://github.com/kubevirt/kubevirt/blob/master/hack/generate.sh) script similarly to the [standard makefile](https://github.com/kubevirt/kubevirt/blob/master/Makefile). It builds all generators (under the `tools` directory) and use them to generate: test mocks, KubeVirt resources and test yamls
- **apidocs**: this is similar to apidocs target in the [standard makefile](ttps://github.com/kubevirt/kubevirt/blob/master/Makefile)
- **build**: this is building all product binaries, and then using a script ([copy-cmd.sh](../assets/2018-06-07-Non-Dockerized-Build/copy-cmd.sh), should be placed under: `hack`) to copy the binaries from their standard location into the `_out` directory, where the cluster management scripts expect them
- **test**: building and running unit tests
  check: using similar code to the one used in the standard makefile: formatting files, fixing package imports and calling go vet
- **functest**: building and running integration tests. After tests are built , they are moved to the `_out` directory so that the standard script for running integration tests would find them
- **cluster-sync**: this is the only "cluster management" target that had to be modified from the standard makefile
