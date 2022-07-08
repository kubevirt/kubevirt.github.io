# COLORS
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
VIOLET := $(shell tput -Txterm setaf 5)
AQUA   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
SELINUX := $(shell [ -x /usr/sbin/getenforce ] && /usr/sbin/getenforce)


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
	@printf "  ${YELLOW}SELINUX_ENABLED${RESET}\tEnable SELinux on containers, [False, True] Will attempt autodetection if unset.\n"
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

ifdef SELINUX_ENABLED
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
                   "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=,Z)
else
		@$(eval export SELINUX_ENABLED='')
endif
else
ifeq ($(SELINUX), Enforcing)
	@$(eval export SELINUX_ENABLED=,Z)
endif
endif
	@echo

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


## Build site. This target should only be used by Netlify and Prow
build: envvar
	@echo "${GREEN}Makefile: Build jekyll site${RESET}"
#	which $(RUBY)
	scripts/update_changelog.sh
	rake
	touch _site/.nojekyll


## Build image localhost/kubevirt-kubevirt.github.io
build_img: | envvar
	@echo "${GREEN}Makefile: Building Image ${RESET}"
	${DEBUG}if [ ! -e "./Dockerfile" ]; then \
	  IMAGE="`echo $${IMGTAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`";  \
	  if [ "`curl https://raw.githubusercontent.com/kubevirt/project-infra/main/images/kubevirt-kubevirt.github.io/Dockerfile -o ./Dockerfile -w '%{http_code}\n' -s`" != "200" ]; then \
	    echo "curl Dockerfile failed... exitting!"; \
	    exit 2; \
	  else \
	    REMOTE=1; \
	  fi; \
	else \
	  IMAGE="`echo $${TAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`"; \
	  echo "DOCKERFILE file: ./Dockerfile"; \
	  echo "Be sure to add changes to upstream: kubevirt/project-infra/main/images/${IMGTAG}/Dockerfile"; \
	  echo; \
	fi; \
	${CONTAINER_ENGINE} rmi ${IMGTAG} 2> /dev/null || echo -n; \
	${BUILD_ENGINE} ${IMGTAG}; \
	if [ "$${REMOTE}" ]; then rm -f Dockerfile > /dev/null 2>&1; fi


## Check external, internal links and links/selectors to userguide on website content
check_links: | envvar stop
	@echo -n "${GREEN}Makefile: Check external and internal links${RESET}"
	${DEBUG}${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock --mount type=tmpfs,destination=/srv/_site --mount type=tmpfs,destination=/srv/.jekyll-cache ${IMGTAG} /bin/bash -c 'cd /srv; rake links:test_external; rake links:test_internal;'


## Check links/selectors to userguide on website content
check_links_selectors: | envvar stop
	@echo "${GREEN}Makefile: Check url selectors to user-guide${RESET}"
#BEGIN BIG SHELL SCRIPT
	${DEBUG}${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock --mount type=tmpfs,destination=/srv/_site --mount type=tmpfs,destination=/srv/.jekyll-cache ${IMGTAG} /bin/bash -c 'cd /srv; rake --trace links:userguide_selectors' | sed -n -e '/HTML-Proofer finished successfully./,$$p' | grep -v 'HTML-Proofer finished successfully.' > links 2> /dev/null; \
	${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/_site --workdir=/srv ${IMGTAG} /bin/bash -c \
	  "for i in \`cat ./links\`; do \
			echo -n 'File: ' && echo \"\$${i}\" | cut -d',' -f 2; \
			echo -n 'Link: ' && echo \"\$${i}\" | cut -d',' -f 1; \
			OPENSSL_CONF=/dev/null casperjs test --concise --arg=\"\$${i}\" /src/check_selectors.js; \
			if [ \"\$$?\" != 0 ]; then break; fi; \
			echo; \
		done" > RETVAL; \
	echo && cat RETVAL; \
	if `egrep "FAIL 1 test executed" RETVAL > /dev/null`; then rm -rf RETVAL links && exit 2; \
	else \
		rm -rf RETVAL links; \
		echo "Complete!"; \
	fi
#END BIG SHELL SCRIPT


## Check markdown linting
check_lint: | envvar stop
	@echo "${GREEN}Makefile: Linting Markdown files using ${LINT_IMAGE}${RESET}"
	${DEBUG}${CONTAINER_ENGINE} run -it --rm --name website --net=host -v ${PWD}:/srv/:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock --mount type=tmpfs,destination=/srv/_site --mount type=tmpfs,destination=/srv/.jekyll-cache --workdir=/srv ${IMGTAG} /bin/bash -c 'markdownlint -c .markdownlint.yaml -i .markdownlintignore **/*.md'
	@echo


## Check spelling on content
check_spelling: | envvar stop
	@echo "${GREEN}Makefile: Check spelling on site content${RESET}"
	${DEBUG}if [ ! -e "./yaspeller.json" ]; then \
		echo "${WHITE}Downloading Dictionary file: https://raw.githubusercontent.com/kubevirt/project-infra/main/images/yaspeller/.yaspeller.json${RESET}"; \
		if ! `curl -fs https://raw.githubusercontent.com/kubevirt/project-infra/main/images/yaspeller/.yaspeller.json -o yaspeller.json`; then \
			echo "${RED}ERROR: Unable to curl yaspeller dictionary file${RESET}"; \
			exit 2; \
		else \
			echo "${WHITE}yaspeller updated ${RESET}"; \
			echo; \
			REMOTE=1; \
		fi; \
	else \
		echo "YASPELLER file: ./yaspeller.json"; \
		echo "Be sure to add changes to upstream: kubevirt/project-infra/main/images/yaspeller/.yaspeller.json"; \
		echo; \
	fi; \
	export IFS=$$'\n'; \
	if `cat ./yaspeller.json 2>&1 | jq > /dev/null 2>&1`; then \
		for i in `${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock -v ./yaspeller.json:/srv/yaspeller.json:ro${SELINUX_ENABLED} ${IMGTAG} /bin/bash -c 'echo; yaspeller -c /srv/yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv'`; do \
			if [[ "$${i}" =~ "✗" ]]; then \
				RETVAL=2; \
			fi; \
		echo "$${i}" | sed -e 's/\/srv\//\.\//g'; \
		done; \
	else \
		echo "${RED}ERROR: yaspeller dictionary file does not exist or is invalid json${RESET}"; \
		RETVAL=1; \
	fi; \
	if [ "$${REMOTE}" ]; then \
		rm -rf yaspeller.json > /dev/null 2>&1; \
	fi; \
	if [ "$${RETVAL}" ]; then exit 2; else echo "Complete!"; fi


## Run site.  App available @ http://0.0.0.0:4000
run: | envvar stop
	@echo "${GREEN}Makefile: Run site${RESET}"
	for i in .jekyll-cache _site Gemfile.lock; do rm -rf ./"$${i}" 2> /dev/null; echo -n; done
	$(eval TEMP_GEMLOCK := $(shell mktemp))
	${CONTAINER_ENGINE} run -d --name website --net=host -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v ${TEMP_GEMLOCK}:/srv/Gemfile.lock:rw${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/_site --mount type=tmpfs,destination=/srv/.jekyll-cache --workdir=/srv ${IMGTAG} /bin/bash -c "jekyll serve --host=0.0.0.0 --trace --force_polling --future"
	rm -f ${TEMP_GEMLOCK}
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check container status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo


## Stop running container
stop: | envvar
	@echo "${GREEN}Makefile: Stop running container${RESET}"
	${CONTAINER_ENGINE} rm -f website 2> /dev/null; echo
	@echo -n
