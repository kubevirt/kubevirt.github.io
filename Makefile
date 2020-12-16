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
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Env Variables:'
	@printf "  ${YELLOW}CONTAINER_ENGINE${RESET}\tSet container engine, [*podman*, docker]\n"
	@printf "  ${YELLOW}BUILD_ENGINE${RESET}\t\tSet build engine, [*buildah*, docker]\n"
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
	@$(eval export BUILD_ENGINE=buildah build-using-dockerfile -t)
else
	@echo ${BUILD_ENGINE}
ifeq ($(shell test "$(BUILD_ENGINE)" = "podman" && printf true), true)
	@$(eval export BUILD_ENGINE=buildah build-using-dockerfile -t)
else ifeq ($(shell test "$(BUILD_ENGINE)" = "docker" && printf "true"), true)
	@$(eval export BUILD_ENGINE=docker build . -t)
else
	@echo ${BUILD_ENGINE}
	@echo "Invalid value for BUILD_ENGINE ... exiting"
endif
endif

ifndef CONTAINER_ENGINE
	@$(eval CONTAINER_ENGINE=podman)
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


## Check external, internal, userguide links
check_links_website: | envvar stop_website
	@echo "${GREEN}Makefile: Check external, internal links${RESET}"
	${DEBUG}for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	${DEBUG}${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c 'bundle install --quiet; rake -- -u'
	@echo
	@echo "${GREEN}Makefile: Check userguide links and userguide selectors${RESET}"
#BEGIN BIG SHELL SCRIPT
	${DEBUG}export IFS=$$'\n'; \
	OUTPUT=`${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c 'bundle install --quiet; rake links:userguide_selectors'`; \
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
	    ${CONTAINER_ENGINE} run -it --rm --name casperjs --net=host -v ${PWD}:/srv:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/jekyll/_site casperjs /bin/bash -c "casperjs test --fail-fast --concise --arg=\"$${i}\" /srv/check_selectors.js"; \
	    echo; \
	  fi; \
	done; \
	if [ "$${RETVAL}" ]; then exit 1; fi; \
	echo "Complete!"
#END BIG SHELL SCRIPT
	@echo


## Check spelling on userguide content
check_spelling_userguide: | envvar stop_userguide
	@echo "${GREEN}Makefile: Check userguide spelling${RESET}"
	${DEBUG}export IFS=$$'\n'; \
	for i in `cd ${GIT_REPO_DIR}/user-guide && ${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ./docs:/srv/docs:ro${SELINUX_ENABLED} -v ${GIT_REPO_DIR}/project-infra/images/yaspeller/.yaspeller.json:/srv/.yaspeller.json:ro${SELINUX_ENABLED} yaspeller /bin/bash -c 'echo; yaspeller -c /srv/.yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv/docs'`; do \
		if [[ "$${i}" =~ "✗" ]]; then \
			export RETVAL=1; \
		fi; \
		echo "$${i}"; \
	done; \
	if [ "$${RETVAL}" ]; then exit 1; fi; \
	echo "Complete!"


## Check spelling on website content
check_spelling_website: | envvar stop_website
	@echo "${GREEN}Makefile: Check website spelling${RESET}"
	${DEBUG}export IFS=$$'\n'; \
	for i in `${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v ${GIT_REPO_DIR}/project-infra/images/yaspeller/.yaspeller.json:/srv/.yaspeller.json:ro${SELINUX_ENABLED} yaspeller /bin/bash -c 'echo; yaspeller -c /srv/.yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv'`; do \
		if [[ "$${i}" =~ "✗" ]]; then \
			export RETVAL=1; \
		fi; \
	  echo "$${i}"; \
	done; \
	if [ "$${RETVAL}" ]; then exit 1; fi; \
	echo "Complete!"


## Build image: casperjs
build_image_casperjs: | envvar stop_casperjs
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/casperjs)
	${DEBUG}$(eval export TAG=localhost/casperjs:latest)
	${DEBUG}$(MAKE) build
	@echo


## Build image: userguide
build_image_userguide: | envvar stop_userguide
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/kubevirt-userguide)
	${DEBUG}$(eval export TAG=localhost/userguide:latest)
	${DEBUG}$(MAKE) build
	@echo


## Build image: yaspeller
build_image_yaspeller: | envvar stop_yaspeller
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/yaspeller)
	${DEBUG}$(eval export TAG=localhost/yaspeller:latest)
	${DEBUG}$(MAKE) build
	@echo


build:
ifeq ($(DIR),)
	@echo "This is a sourced target!"
	@echo "Do not run this target directly... exitting!"
	exit 1
endif
	@echo "${GREEN}Makefile: ${TAG}${RESET}" | sed -e 's/-/ /g' -e 's/: build/: Building/g'
	cd ${DIR} && \
	${BUILD_ENGINE} rmi ${TAG} || echo -n && \
	${BUILD_ENGINE} ${TAG}


## Run website and userguide containers
run: | envvar run_userguide run_website status


## Run userguide image.   App available @ http://0.0.0.0:8000
run_userguide: | envvar stop_userguide
	@echo "${GREEN}Makefile: Run userguide image${RESET}"
	cd ${GIT_REPO_DIR}/user-guide && \
	for i in site; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done && \
	${CONTAINER_ENGINE} run -d --name userguide --net=host -v ./:/userguide:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/userguide/site localhost/userguide:latest /bin/bash -c "mkdocs build -f /userguide/mkdocs.yml && mkdocs serve -f /userguide/mkdocs.yml -a 0.0.0.0:8000"
	@echo


## Run website image.  App available @ http://0.0.0.0:4000
run_website: | envvar stop_website
	@echo "${GREEN}Makefile: Run website image${RESET}"
	for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	${CONTAINER_ENGINE} run -d --name website --net=host -v ${PWD}:/srv/jekyll:ro${SELINUX_ENABLED} -v /dev/null:/srv/jekyll/Gemfile.lock --mount type=tmpfs,destination=/srv/jekyll/_site --mount type=tmpfs,destination=/srv/jekyll/.jekyll-cache jekyll/jekyll /bin/bash -c "jekyll serve --force_polling --future"
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check image status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo -n


## Stop website and userguide containers
stop: | envvar stop_website stop_userguide status


## Stop casperjs image
stop_casperjs: | envvar
	@echo "${GREEN}Makefile: Stop casperjs image${RESET}"
	${CONTAINER_ENGINE} rm -f casperjs 2> /dev/null; echo
	@echo -n


## Stop userguide image
stop_userguide: | envvar
	@echo "${GREEN}Makefile: Stop userguide image${RESET}"
	${CONTAINER_ENGINE} rm -f userguide 2> /dev/null; echo
	@echo -n


## Stop website image
stop_website: | envvar
	@echo "${GREEN}Makefile: Stop website image${RESET}"
	${CONTAINER_ENGINE} rm -f website 2> /dev/null; echo
	@echo -n


## Stop yaspeller image
stop_yaspeller: | envvar
	@echo "${GREEN}Makefile: Stop yaspeller image${RESET}"
	${CONTAINER_ENGINE} rm -f yaspeller 2> /dev/null; echo
	@echo
