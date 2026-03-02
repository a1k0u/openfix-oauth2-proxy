BASE_PATH ?= /var/cache/pbuilder/base.cow
BUILD_ROOT ?= .

.PHONY: all
all: oauth2-proxy.deb

oauth2-proxy.deb: envsubst.deb mockoidc.deb redislock.deb minisentinel.deb go-redis-v9.deb
redislock.deb: miniredis.deb go-redis-v9.deb
minisentinel.deb: miniredis.deb
miniredis.deb: gopher-lua.deb

%.deb: BUILD_PATH = $(BUILD_ROOT)/.$*.build
%.deb:
	@echo "Build $@ with prerequisites $^ in $(BUILD_PATH)"

	mkdir -p $(BUILD_PATH)/cow $(BUILD_PATH)/deb

	-ln -P openfix_*.deb $(BUILD_PATH)/deb
	cd $(BUILD_PATH)/deb && (dpkg-scanpackages . | gzip -9c > Packages.gz)

	cd $* && gbp buildpackage \
		--git-pbuilder \
		--git-ignore-branch \
		--git-pbuilder-options="\
			--override-config \
			--hookdir $(abspath hooks) \
			--basepath $(abspath $(BASE_PATH)) \
			--buildplace $(abspath $(BUILD_PATH)/cow) \
			--bindmounts $(abspath $(BUILD_PATH)/deb) \
			--othermirror 'deb [trusted=yes] file:$(abspath $(BUILD_PATH)/deb) ./' \
			--buildresult $(abspath $(BUILD_PATH)) \
		"

	ln -P $(BUILD_PATH)/*$*-*.deb $@
	ln -P $(BUILD_PATH)/*$*-*.deb openfix_$@

	find $(BUILD_PATH) -maxdepth 1 -type f -exec mv -t . {} +
	
	rm -rf $(BUILD_PATH)


.PHONY: init init-deps init-keys init-cowbuilder init-submodules
init: init-deps init-keys init-cowbuilder init-submodules

init-deps:
	-[ -f /etc/pbuilderrc ] || echo "MIRRORSITE=http://deb.debian.org/debian" > /etc/pbuilderrc
	apt-get update && apt-get install -y \
		build-essential \
		debhelper \
		devscripts \
		git-buildpackage \
		pbuilder \
		cowbuilder \
		fakeroot \
		dh-golang \
		equivs \
		debian-archive-keyring \
		debootstrap

init-keys:
	curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc | gpg --dearmor -o /etc/apt/keyrings/debian-archive-12.gpg

init-submodules:
	git submodule update --init --recursive --rebase
	git submodule foreach 'git checkout debian/sid'

init-cowbuilder: init-deps init-keys
	cowbuilder --create \
		--buildplace /var/cache/pbuilder/base.cow \
		--mirror http://deb.debian.org/debian \
		--distribution sid \
		--debootstrapopts --keyring=/etc/apt/keyrings/debian-archive-12.gpg
