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
	@printf "  ${YELLOW}GIT_REPO_DIR${RESET}\t\tSet path to git repos, [*~/git*, /path/to/git/repos]\n"
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
	@$(eval export DEBUG=@)
else
ifeq ($(shell test "$(DEBUG)" = True  -o  \
	                 "$(DEBUG)" = true && printf "true"), true)
	@$(eval export DEBUG=)
else
	@$(eval export DEBUG=@)
endif
endif

ifndef GIT_REPO_DIR
	@$(eval GIT_REPO_DIR=~/git)
endif

ifdef SELINUX_ENABLED
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
                   "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=,Z)
endif
endif
	@echo


## Check external, internal links and links/selectors to userguide on website content
check_links: | envvar stop
	@echo "${GREEN}Makefile: Check external, internal links on website content${RESET}"
	${DEBUG}for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	${DEBUG}${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c 'cd /srv/jekyll; bundle install --quiet; rake -- -u'
	@echo
	@echo "${GREEN}Makefile: Check links and selectors to userguide on website content${RESET}"
#BEGIN BIG SHELL SCRIPT
	${DEBUG}export IFS=$$'\n'; \
	cd ${GIT_REPO_DIR}/user-guide && make run; \
	OUTPUT=`${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c 'cd /srv/jekyll; bundle install --quiet; rake links:userguide_selectors'`; \
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
	    ${CONTAINER_ENGINE} run -it --rm --name casperjs --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/jekyll/_site casperjs /bin/bash -c "casperjs test --fail-fast --concise --arg=\"$${i}\" /srv/check_selectors.js"; \
	    echo; \
	  fi; \
	done; \
	cd ${GIT_REPO_DIR}/user-guide && make stop; \
	if [ "$${RETVAL}" ]; then exit 1; fi; \
	echo "Complete!"
#END BIG SHELL SCRIPT
	@echo


## Check spelling on content
check_spelling: | envvar stop
	@echo "${GREEN}Makefile: Check spelling on site content${RESET}"
	@echo "Dictionary file: https://raw.githubusercontent.com/kubevirt/project-infra/master/images/yaspeller/.yaspeller.json"
	${DEBUG}export IFS=$$'\n'; \
  if [ "`curl https://raw.githubusercontent.com/kubevirt/project-infra/master/images/yaspeller/.yaspeller.json -o yaspeller.json -w '%{http_code}\n' -s`" != "200" ]; then \
		echo "Unable to curl yaspeller dictionary file"; \
		RETVAL=1; \
	fi; \
	if `cat ./yaspeller.json 2>&1 | jq > /dev/null 2>&1`; then \
		for i in `${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v ./yaspeller.json:/srv/yaspeller.json:ro${SELINUX_ENABLED} yaspeller /bin/bash -c 'echo; yaspeller -c /srv/yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv'`; do \
			if [[ "$${i}" =~ "✗" ]]; then \
				RETVAL=1; \
			fi; \
	  echo "$${i}"; \
		done; \
	else \
		echo "yaspeller dictionary file does not exist or is invalid json"; \
		RETVAL=1; \
	fi; \
	rm -rf yaspeller.json > /dev/null 2>&1; \
	if [ "$${RETVAL}" ]; then exit 1; else echo "Complete!"; fi


## Build image: casperjs
build_image_casperjs: stop_casperjs
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/casperjs)
	${DEBUG}$(eval export TAG=localhost/casperjs:latest)
	${DEBUG}$(MAKE) build_image
	@echo


## Build image: yaspeller
build_image_yaspeller: stop_yaspeller
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/yaspeller)
	${DEBUG}$(eval export TAG=localhost/yaspeller:latest)
	${DEBUG}$(MAKE) build_image
	@echo


build_image: envvar
	@echo "${GREEN}Makefile: Building image: ${TAG}${RESET}"
ifeq ($(DIR),)
	@echo "This is a sourced target!"
	@echo "Do not run this target directly... exitting!"
	exit 1
endif
	cd ${DIR} && \
	(${CONTAINER_ENGINE} rmi ${TAG} || echo -n) && \
	${BUILD_ENGINE} ${TAG}


## Run site.  App available @ http://0.0.0.0:4000
run: | envvar stop
	@echo "${GREEN}Makefile: Run site${RESET}"
	for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	${CONTAINER_ENGINE} run -d --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c "jekyll serve --force_polling --future"
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check image status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo


## Stop site
stop: | envvar
	@echo "${GREEN}Makefile: Stop site${RESET}"
	${CONTAINER_ENGINE} rm -f website 2> /dev/null; echo
	@echo -n


## Stop casperjs image
stop_casperjs: | envvar
	@echo "${GREEN}Makefile: Stop casperjs image${RESET}"
	${CONTAINER_ENGINE} rm -f casperjs 2> /dev/null; echo
	@echo -n

## Stop yaspeller image
stop_yaspeller: | envvar
	@echo "${GREEN}Makefile: Stop yaspeller image${RESET}"
	${CONTAINER_ENGINE} rm -f yaspeller 2> /dev/null; echo
	@echo -n
