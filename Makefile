BASE_PATH ?= /var/cache/pbuilder/base.cow
APT_CACHE_PATH ?= /var/cache/pbuilder/aptcache
BUILD_ROOT ?= .
ARTIFACTS_PATH ?= .

.PHONY: all
all: oauth2-proxy.deb

oauth2-proxy.deb: mockoidc.deb redislock.deb minisentinel.deb
redislock.deb: miniredis.deb
minisentinel.deb: miniredis.deb
miniredis.deb: gopher-lua.deb

%.deb: BUILD_PATH = $(BUILD_ROOT)/.$*.build
%.deb:
	@echo "Build $@ with prerequisites $^ in $(BUILD_PATH)"

	mkdir -p $(BUILD_PATH)/cow $(BUILD_PATH)/deb

	-ln -P $(ARTIFACTS_PATH)/openfix_*.deb $(BUILD_PATH)/deb
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
			--aptcache $(abspath $(APT_CACHE_PATH)) \
			--othermirror 'deb [trusted=yes] file:$(abspath $(BUILD_PATH)/deb) ./' \
			--buildresult $(abspath $(BUILD_PATH)) \
		"

	ln -P $(BUILD_PATH)/*$*-*.deb $(ARTIFACTS_PATH)/$@
	ln -P $(BUILD_PATH)/*$*-*.deb $(ARTIFACTS_PATH)/openfix_$@

	find $(BUILD_PATH) -maxdepth 1 -type f -exec mv -t $(ARTIFACTS_PATH) {} +
	
	rm -rf $(BUILD_PATH)

.PHONY: init init-deps init-keys init-dirs init-cowbuilder init-submodules
init: init-deps init-keys init-dirs init-cowbuilder init-submodules

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
	mkdir -p /etc/apt/keyrings
	curl -fsSL \
		https://ftp-master.debian.org/keys/archive-key-12.asc \
		https://ftp-master.debian.org/keys/archive-key-13.asc \
		| gpg --dearmor -o /etc/apt/keyrings/debian-archive.gpg

init-dirs:
	mkdir -p $(dir $(BASE_PATH)) $(APT_CACHE_PATH)

init-submodules:
	git submodule update --init --recursive --rebase
	git submodule foreach 'git checkout debian/sid'

init-cowbuilder: init-deps init-dirs init-keys
	cowbuilder --create \
		--basepath $(abspath $(BASE_PATH)) \
		--mirror http://deb.debian.org/debian \
		--distribution sid \
		--debootstrapopts --keyring=/etc/apt/keyrings/debian-archive.gpg

# Run autopkgtest
# autopkgtest oauth2-proxy_7.14.2-1_arm64.changes -- unshare --release unstable
