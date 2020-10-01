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
ifndef GIT_REPO_DIR
	@$(eval GIT_REPO_DIR=~/git)
endif

ifndef CONTAINER_ENGINE
	@$(eval CONTAINER_ENGINE=podman)
endif

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

ifndef SELINUX_ENABLED
	@$(eval export SELINUX_ENABLED=)
else
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
                   "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=:Z)
else
		@$(eval export SELINUX_ENABLED=)
endif
endif
	@echo


## Check external, internal, userguide links
check_links_website: | envvar stop-kubevirtio
	@echo "${GREEN}Makefile: Check external, internal, userguide links${RESET}"
	${CONTAINER_ENGINE} run -it --rm --name kubevirtio --net=host -v ${PWD}:/srv/jekyll"${SELINUX_ENABLED}" --mount type=tmpfs,destination=/srv/jekyll/_site"${SELINUX_ENABLED}" jekyll/jekyll /bin/bash -c "bundle install --quiet; rake"
	@echo

	@echo "${GREEN}Makefile: Check userguide selectors${RESET}"
	for i in `${CONTAINER_ENGINE} run -it --rm --name kubevirtio --net=host -v ${PWD}:/srv/jekyll"${SELINUX_ENABLED}" --mount type=tmpfs,destination=/srv/jekyll/_site"${SELINUX_ENABLED}" jekyll/jekyll /bin/bash -c "bundle install --quiet; rake links:userguide_selectors" 2> /dev/null`; do \
		if [[ "$${i}" =~ "failure!" ]]; then \
		  echo "  ${RED}* FAILED ... HTML-Proofer failed.  Run 'make check_userguide_links' to find broken links${RESET}"; \
			break; \
		fi; \
		if [[ "$${i}" =~ https?:// ]]; then \
			echo -n "${AQUA} * " && \
			echo "$${i}" | cut -d"," -f 1,2 | sed -e 's/^/"File": "/g' -e 's/,/", "Link": "/g' -e 's/\\$$/"/g' && \
			echo -n "${RESET}"; \
			if `egrep -q "/#(\w|-|_)+" <<< "$${i}"`; then \
				${CONTAINER_ENGINE} run -it --rm --name casperjs --net=host -v ${PWD}:/srv"${SELINUX_ENABLED}" --mount type=tmpfs,destination=/srv/jekyll/_site"${SELINUX_ENABLED}" casperjs /bin/bash -c "casperjs test --fail-fast --concise --arg=\"$${i}\" /srv/check_selectors.js"; \
			else \
				echo "  ${RED}* FAILED ... Docsify ?id= links need to be migrated to mkdocs${RESET}"; \
			fi; \
		fi; \
	done
	@echo

## Check spelling on kubevirtio content
check_spelling_kubevirtio: | envvar
	@echo "${GREEN}Makefile: Check kubevirtio spelling${RESET}"
	${CONTAINER_ENGINE} run -it --rm --name yaspeller --net=host -v `pwd`:/srv"${SELINUX_ENABLED}" -v ${GIT_REPO_DIR}/project-infra/images/yaspeller/.yaspeller.json:/srv/.yaspeller.json"${SELINUX_ENABLED}" --mount type=tmpfs,destination=/srv/jekyll/_site"${SELINUX_ENABLED}" yaspeller /bin/bash -c "echo; yaspeller -c /srv/.yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv" | \
	sed -e 's#\/srv#${GIT_REPO_DIR}\/\./#g'
	@echo


## Check spelling on userguide content
check_spelling_userguide: | envvar
	@echo "${GREEN}Makefile: Check userguide spelling${RESET}"
	cd ${GIT_REPO_DIR}/user-guide && \
	${CONTAINER_ENGINE} run -it --rm --name yaspeller --net=host -v `pwd`:/srv"${SELINUX_ENABLED}" -v ${GIT_REPO_DIR}/project-infra/images/yaspeller/.yaspeller.json:/srv/.yaspeller.json"${SELINUX_ENABLED}" yaspeller /bin/bash -c "echo; yaspeller -c /srv/.yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv" | \
	sed -e 's#\/srv#${GIT_REPO_DIR}\/user-guide#g'
	@echo


## Build casperjs image
build-casperjs-image: | envvar stop-casperjs
	@$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/casperjs)
	@$(eval export TAG=localhost/casperjs:latest)
	@$(MAKE) build
	@echo


## Build userguide image
build-userguide-image: | envvar stop-userguide
	@$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/kubevirt-userguide)
	@$(eval export TAG=localhost/userguide:latest)
	@$(MAKE) build
	@echo


## Build yaspeller image
build-yaspeller-image: | envvar stop-yaspeller
	@$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/yaspeller)
	@$(eval export TAG=localhost/yaspeller:latest)
	@$(MAKE) build
	@echo


build:
ifeq ($(DIR),)
	@echo "This is a sourced target!"
	@echo "Do not run this target directly... exitting!"
	exit 1
endif
	@echo "${GREEN}Makefile: ${TAG}${RESET}" | sed -e 's/-/ /g' -e 's/: build/: Building/g'
	cd ${DIR} && \
	${BUILD_ENGINE} ${TAG}


## Run kubevirtio and userguide containers
run: | envvar run-userguide run-kubevirtio status


## Run kubevirtio image.  App available @ http://0.0.0.0:4000
run-kubevirtio: | envvar stop-kubevirtio
	@echo "${GREEN}Makefile: Run kubevirtio image${RESET}"
	for i in .jekyll-cache _site; do mkdir ./"$${i}" 2> /dev/null; chmod 777 ./"$${i}"; echo -n; done
	for i in Gemfile.lock; do touch ./"$${i}" && chmod 777 ./"$${i}"; echo -n; done
	${CONTAINER_ENGINE} run -d --name kubevirtio --net=host -v ${PWD}:/srv/jekyll"${SELINUX_ENABLED}" --mount type=tmpfs,destination=/srv/jekyll/_site"${SELINUX_ENABLED}" -e JEKYLL_UID=`id -u` jekyll/jekyll /bin/bash -c "jekyll serve --force_polling --future"
	@echo


## Run userguide image.   App available @ http://0.0.0.0:8000
run-userguide: | envvar stop-userguide
	@echo "${GREEN}Makefile: Run userguide image${RESET}"
	cd ${GIT_REPO_DIR}/user-guide; \
	for i in site; do mkdir ./"$${i}" 2> /dev/null; chmod 777 ./"$${i}"; echo -n; done; \
	${CONTAINER_ENGINE} run -d --name userguide --net=host -v `pwd`:/userguide"${SELINUX_ENABLED}" localhost/userguide:latest /bin/bash -c "mkdocs build -f /userguide/mkdocs.yml && mkdocs serve -f /userguide/mkdocs.yml -a 0.0.0.0:8000"
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check image status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo


## Stop kubevirtio and userguide containers
stop: | envvar stop-kubevirtio stop-userguide status


## Stop casperjs image
stop-casperjs: | envvar
	@echo "${GREEN}Makefile: Stop casperjs image${RESET}"
	${CONTAINER_ENGINE} rm -f casperjs 2> /dev/null; echo
	@echo


## Stop kubevirtio image
stop-kubevirtio: | envvar
	@echo "${GREEN}Makefile: Stop kubevirtio image${RESET}"
	${CONTAINER_ENGINE} rm -f kubevirtio 2> /dev/null; echo


## Stop userguide image
stop-userguide: | envvar
	@echo "${GREEN}Makefile: Stop userguide image${RESET}"
	${CONTAINER_ENGINE} rm -f userguide 2> /dev/null; echo


## Stop yaspeller image
stop-yaspeller: | envvar
	@echo "${GREEN}Makefile: Stop yaspeller image${RESET}"
	${CONTAINER_ENGINE} rm -f yaspeller 2> /dev/null; echo
