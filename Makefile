LOCAL_REPO_DIR := /srv/apt-local-repositroy

.PHONY: build-dep load-deps

build-dep:
	@if [ -z "$${DIR}" ]; then echo "Usage: make build-dep DIR=/path/to/folder"; exit 1; fi
	cd "$${DIR}" && gbp buildpackage --git-pbuilder


load-deps:
	mkdir -p $(LOCAL_REPO_DIR)
	mv -f ./*.deb $(LOCAL_REPO_DIR) || true
	(cd $(LOCAL_REPO_DIR); dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz)
	echo "BINDMOUNTS=$(LOCAL_REPO_DIR)" > "$$HOME/.pbuilderrc"
	echo "OTHERMIRROR=\"deb [trusted=yes] file:$(LOCAL_REPO_DIR) ./\"" >> "$$HOME/.pbuilderrc"
	sudo cowbuilder --update --override-config

build-deps:
	make build-dep DIR=envsubst
	make build-dep DIR=gopher-lua
	make build-dep DIR=go-redis-v9
	make build-dep DIR=mockoidc
	make load-deps
	make build-dep DIR=redislock
	make build-dep DIR=miniredis
	make load-deps
	make build-dep DIR=minisentinel
