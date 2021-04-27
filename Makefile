# COLORS
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
VIOLET := $(shell tput -Txterm setaf 5)
AQUA   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20


## Show help
help:
	@echo ''
	@echo 'Makefile for website jekyll application'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Env Variables:'
	@printf "  ${YELLOW}CONTAINER_ENGINE${RESET}\tSet container engine, [*podman*, docker]\n"
	@printf "  ${YELLOW}BUILD_ENGINE${RESET}\t\tSet build engine, [*podman*, buildah, docker]\n"
	@printf "  ${YELLOW}SELINUX_ENABLED${RESET}\tEnable SELinux on containers, [*False*, True]\n"
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET}\t${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)


envvar:
ifndef BUILD_ENGINE
	@$(eval export BUILD_ENGINE=podman build . -t)
else
ifeq ($(shell test "${BUILD_ENGINE}" == "podman" || test "${BUILD_ENGINE}" == "podman build . -t" && printf true), true)
	@$(eval export BUILD_ENGINE=podman build . -t)
else ifeq ($(shell test "${BUILD_ENGINE}" == "buildah" || test "${BUILD_ENGINE}" == "buildah build-using-dockerfile -t" && printf "true"), true)
	@$(eval export BUILD_ENGINE=buildah build-using-dockerfile -t)
else ifeq ($(shell test "${BUILD_ENGINE}" == "docker" || test "${BUILD_ENGINE}" == "docker build . -t" && printf "true"), true)
	@$(eval export BUILD_ENGINE=docker build . -t)
else
	@echo ${BUILD_ENGINE}
	@echo "Invalid value for BUILD_ENGINE ... exiting"
endif
endif

ifndef CONTAINER_ENGINE
	@$(eval CONTAINER_ENGINE=podman)
else
ifeq ($(shell test "$(CONTAINER_ENGINE)" = "podman" && printf true), true)
	@$(eval export CONTAINER_ENGINE=podman)
else ifeq ($(shell test "$(CONTAINER_ENGINE)" = "docker" && printf "true"), true)
	@$(eval export CONTAINER_ENGINE=docker)
else
	@echo ${CONTAINER_ENGINE}
	@echo "Invalid value for CONTAINER_ENGINE ... exiting"
endif
endif

ifndef DEBUG
	@$(eval export DEBUG=@)~
else
ifeq ($(shell test "$(DEBUG)" = True  -o  \
	                 "$(DEBUG)" = true && printf "true"), true)
	@$(eval export DEBUG=)
else
	@$(eval export DEBUG=@)
endif
endif

ifdef SELINUX_ENABLED
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
                   "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=,Z)
else
		@$(eval export SELINUX_ENABLED='')
endif
endif
	@echo

ifndef REPOPATH
	@$(eval export REPOPATH=https://raw.githubusercontent.com/kubevirt/project-infra/master/images/kubevirt-kubevirt.github.io)
endif

ifndef IMGTAG
	@$(eval export IMGTAG=localhost/kubevirt-kubevirt.github.io)
else
ifeq ($(shell test $IMGTAG > /dev/null 2>&1 && printf "true"), true)
	@echo WARN: Using IMGTAG=$$IMGTAG
	@echo
else
	@$(eval export IMGTAG=localhost/kubevirt-kubevirt.github.io)
endif
endif


## Build image localhost/kubevirt.io
build_img: | envvar
	@echo "${GREEN}Makefile: Building Image ${RESET}"
	${DEBUG}if [ ! -e "./Dockerfile" ]; then \
	  IMAGE="`echo $${IMGTAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`";  \
	  if [ "`curl $${REPOPATH}/Dockerfile -o ./Dockerfile -w '%{http_code}\n' -s`" != "200" ]; then \
	    echo "curl Dockerfile failed... exitting!"; \
	    exit 2; \
	  else \
	    REMOTE=1; \
	  fi; \
	else \
	  IMAGE="`echo $${TAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`"; \
	  echo "DOCKERFILE file: ./Dockerfile"; \
	  echo "Be sure to add changes to upstream: kubevirt/project-infra/master/images/${IMGTAG}/Dockerfile"; \
	  echo; \
	fi; \
	${CONTAINER_ENGINE} rmi ${IMGTAG} 2> /dev/null || echo -n; \
	${BUILD_ENGINE} ${IMGTAG}
	if [ "$${REMOTE}" ]; then rm -f Dockerfile > /dev/null 2>&1; fi
	


## Check external, internal links and links/selectors to userguide on website content
check_links: | envvar stop
	${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache ${IMGTAG} /bin/bash -c 'cd /srv/jekyll; rake -- -u' # ? check internal external links
#BEGIN BIG SHELL SCRIPT
	${DEBUG}export IFS=$$'\n'; \
	OUTPUT=`${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache ${IMGTAG} /bin/bash -c 'cd /srv/jekyll; rake --trace links:userguide_selectors'`; \
	if [ `echo "$${OUTPUT}" | egrep "HTML-Proofer found [0-9]+ failure(s)?" > /dev/null 2>&1` ]; then \
	  echo "$${OUTPUT}"; \
	  exit 1; \
	fi; \
	for i in `echo "$${OUTPUT}" | egrep "https?://.*,.*"`; do \
	  /bin/echo -n "${AQUA}"; \
	  echo -n "File: " && echo "$${i}" | cut -d"," -f 2; \
	  echo -n "Link: " && echo "$${i}" | cut -d"," -f 1; \
	  /bin/echo -n "${RESET}"; \
	  if `egrep -q "/user-guide/#.*(\?id=)?" <<< "$${i}"`; then \
	    RETVAL=1; \
	    echo "  ${RED}* FAILED ... Docsify /user-guide/#.*(\?id=)? links need to be migrated to mkdocs${RESET}"; \
	    echo; \
	  else \
	    ${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/jekyll/_site ${IMGTAG} /bin/bash -c "casperjs test --fail-fast --concise --arg=\"$${i}\" /src/check_selectors.js"; \
	    echo; \
	  fi; \
	done; \
	if [ "$${RETVAL}" ]; then exit 1; fi; \
	echo "Complete!"
#END BIG SHELL SCRIPT
	@echo


## Check spelling on content
check_spelling: | envvar stop
	@echo "${GREEN}Makefile: Check spelling on site content${RESET}"
	${DEBUG} curl $${REPOPATH}/update-yaspeller.sh | bash - 
	${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock --workdir=/srv ${IMGTAG} /bin/bash -c 'yaspeller -c /srv/.yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv'


## Run site.  App available @ http://0.0.0.0:4000
run: | envvar stop
	@echo "${GREEN}Makefile: Run site${RESET}"
	for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	${CONTAINER_ENGINE} run -d --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache --workdir=/srv/jekyll ${IMGTAG} /bin/bash -c "jekyll serve --host=0.0.0.0 --trace --force_polling --future"
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check Container status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo


## Stop site
stop: | envvar
	@echo "${GREEN}Makefile: Stop site${RESET}"
	${CONTAINER_ENGINE} rm -f website 2> /dev/null; echo
	@echo -n
