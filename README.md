## Debian packaging of oauth2-proxy

### Build

Just run command bellow to build oauth2-proxy and all its dependencies:
```bash
make
```

To speed up the build process, you can build the dependencies in parallel:
```bash
make -j$(nproc)
```

Install build dependencies, setup cowbuilder and prepare submodules (_to do step by step, run targets inside makefile_):
```bash
make init
```

Build package with Docker and save it to the artifacts directory:
```bash
CONTAINER_NAME=oauth2-proxy-debian
IMAGE_NAME=debian-builder
ARTIFACTS_PATH=$(pwd)/.build

mkdir -p $ARTIFACTS_PATH
docker build -t $IMAGE_NAME -f Dockerfile .

docker run \
--privileged \
--rm -it \
--name $CONTAINER_NAME \
--volume $ARTIFACTS_PATH:/artifacts:rw \
--entrypoint /bin/bash \
$IMAGE_NAME \
-c '''
  git clone https://github.com/a1k0u/openfix-oauth2-proxy.git
  cd openfix-oauth2-proxy
  
  mkdir -p /artifacts-local
  make init
  make -j$(nproc) BUILD_ROOT=/tmp/$RANDOM ARTIFACTS_PATH=/artifacts-local

  mv /artifacts-local/* /artifacts/
'''

docker image rm $IMAGE_NAME
```

### Road map

#### Overall plan

- [x] Package oauth2-proxy to debian package
  - [x] Includes all control dependencies
  - [x] No implicit dependencies on other packages inside
  - [x] Correct debian package structure
  - [ ] Builds in latest stable debian release
  - [x] Consists autopkgtest
  - [x] Passes debian/tests
- [x] Everything builds in CI
- [ ] Include in sid repository

#### Packages

- envsubst (`golang-github-a8m-envsubst`)
  - [x] [ITP #1127770](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127770)
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-a8m-envsubst](https://salsa.debian.org/go-team/packages/golang-github-a8m-envsubst)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- miniredis (`golang-github-alicebob-miniredis`)
  - [x] [ITP #1127854](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127854). Initially ITA, switched to ITP since the package had not been updated for a long time.
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-alicebob-miniredis](https://salsa.debian.org/go-team/packages/golang-github-alicebob-miniredis)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- minisentinel (`golang-github-bose-minisentinel`)
  - [x] [ITP #1127771](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127771)
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-bose-minisentinel](https://salsa.debian.org/go-team/packages/golang-github-bose-minisentinel)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- mockoidc (`golang-github-oauth2-proxy-mockoidc`)
  - [x] [ITP #1127772](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127772)
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-oauth2-proxy-mockoidc](https://salsa.debian.org/go-team/packages/golang-github-oauth2-proxy-mockoidc)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- redislock (`golang-github-bsm-redislock`)
  - [x] [ITP #1127762](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127762)
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-bsm-redislock](https://salsa.debian.org/go-team/packages/golang-github-bsm-redislock)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship
  - [x] Write tests with miniredis (https://github.com/bsm/redislock/pull/82)

- go-redis-v9 (`golang-github-redis-go-redis-v9`)
  - [x] [ITP #1127858](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1127858)
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-redis-go-redis-v9](https://salsa.debian.org/go-team/packages/golang-github-redis-go-redis-v9)
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- gopher-lua (`golang-github-yuin-gopher-lua`)
  - [ ] The package has not been updated for a long time; an ITA should be filed
  - [x] Package builds
  - [x] Salsa repository: [go-team/packages/golang-github-yuin-gopher-lua](https://salsa.debian.org/go-team/packages/golang-github-yuin-gopher-lua)
  - [ ] Linter: not run
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship

- oauth2-proxy
  - [x] [ITP #982891](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=982891)
  - [x] Package builds
  - [ ] Salsa repository
  - [x] Linter
  - [ ] Upload to Salsa repository
  - [ ] Request sponsorship
  - [x] Write patch for coreos/go-oidc/v3 to downgrade to v3.4.0
  - [x] Write patch for google-cloud-go-compute-metadata
