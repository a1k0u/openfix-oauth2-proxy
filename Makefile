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

	$(foreach deb, $^, ln -P $(abspath $(deb)) $(BUILD_PATH)/deb;)
	cd $(BUILD_PATH)/deb && (dpkg-scanpackages . | gzip -9c > Packages.gz)

	cd $* && gbp buildpackage \
		--git-pbuilder \
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
	find $(BUILD_PATH) -maxdepth 1 -type f -exec mv -t . {} +
	
	rm -rf $(BUILD_PATH)
