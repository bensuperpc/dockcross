
#
# Parameters
#

# Name of the docker executable
DOCKER = docker

# Docker organization to pull the images from
ORG = bensuperpc

# Directory where to generate the dockcross script for each images (e.g bin/dockcross-manylinux2014-x64)
BIN = ./bin

# These images are built using the "build implicit rule"
# EXTEND_STANDARD_IMAGES = linux-armv8-rpi4-all linux-armv8-rpi3-all

STANDARD_IMAGES = avr linux-s390x android-arm android-arm64 android-x86 android-x86_64 linux-x86 linux-x64 linux-x64-clang linux-armv8 linux-armv8-musl linux-armv8-rpi3 linux-armv8-rpi4 linux-armv5 linux-m68k linux-armv5-musl linux-armv6-rpi1 linux-armv6-musl linux-armv6-rpi-old linux-armv7 linux-armv7a linux-armv7-rpi2 linux-armv7l-musl linux-mips linux-mips64 linux-mips64el-n64 linux-mipsel linux-ppc32 linux-ppc64 linux-riscv64 windows-static-x86 windows-static-x64 windows-static-x64-posix windows-shared-x86 windows-shared-x64 windows-shared-x64-posix

# Generated Dockerfiles.
GEN_IMAGES = avr linux-s390x android-arm android-arm64 linux-x86 linux-x64 linux-x64-clang linux-mips linux-mips64 linux-mipsel manylinux2014-x64 manylinux2014-x86 manylinux2014-aarch64 linux-m68k web-wasm linux-armv8 linux-armv8-musl linux-armv8-rpi3 linux-armv8-rpi4 linux-ppc32 linux-ppc64 windows-static-x86 windows-static-x64 windows-static-x64-posix windows-shared-x86 windows-shared-x64 windows-shared-x64-posix linux-mips64el-n64 linux-armv7 linux-armv7a linux-armv7l-musl linux-armv6-rpi1 linux-armv6-musl linux-armv6-rpi-old linux-armv7-rpi2 linux-armv5 linux-armv5-musl linux-riscv64
EXT_GEN_IMAGES = linux-armv8-rpi4.full linux-armv8-rpi3.full linux-armv7-rpi2.full linux-armv7.full linux-armv7a.full linux-armv6-rpi1.full linux-armv8.full

GEN_IMAGE_DOCKERFILES = $(addsuffix /Dockerfile,$(EXT_GEN_IMAGES)) $(addsuffix /Dockerfile,$(GEN_IMAGES))

# These images are expected to have explicit rules for *both* build and testing
NON_STANDARD_IMAGES = web-wasm manylinux2014-x64 manylinux2014-x86 manylinux2014-aarch64 pvsneslib cc65 psn00bsdk sgdk

DOCKER_COMPOSITE_SOURCES = common.docker common.debian common.manylinux common.crosstool common.windows common-manylinux.crosstool common.dockcross common.lib common.label-and-env

# This list all available images
IMAGES = $(STANDARD_IMAGES) $(NON_STANDARD_IMAGES) $(EXTEND_IMAGES)

# Optional arguments for test runner (test/run.py) associated with "testing implicit rule"
linux-ppc64.test_ARGS = --languages C
windows-static-x86.test_ARGS = --exe-suffix ".exe"
windows-static-x64.test_ARGS = --exe-suffix ".exe"
windows-static-x64-posix.test_ARGS = --exe-suffix ".exe"
windows-shared-x86.test_ARGS = --exe-suffix ".exe"
windows-shared-x64.test_ARGS = --exe-suffix ".exe"
windows-shared-x64-posix.test_ARGS = --exe-suffix ".exe"

# On CircleCI, do not attempt to delete container
# See https://circleci.com/docs/docker-btrfs-error/
RM = --rm
ifeq ("$(CIRCLECI)", "true")
	RM =
endif

# Tag images with date and Git short hash in addition to revision
TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)

#
# images: This target builds all IMAGES (because it is the first one, it is built by default)
#
images: base $(IMAGES)

all: base $(IMAGES)

#
# test: This target ensures all IMAGES are built and run the associated tests
#
test: base.test $(addsuffix .test,$(IMAGES))

#
# Generic Targets (can specialize later).
#

$(GEN_IMAGE_DOCKERFILES) Dockerfile: %Dockerfile: %Dockerfile.in $(DOCKER_COMPOSITE_SOURCES)
	sed \
		-e '/common.docker/ r common.docker' \
		-e '/common.debian/ r common.debian' \
		-e '/common.manylinux/ r common.manylinux' \
		-e '/common.crosstool/ r common.crosstool' \
		-e '/common-manylinux.crosstool/ r common-manylinux.crosstool' \
		-e '/common.windows/ r common.windows' \
		-e '/common.dockcross/ r common.dockcross' \
		-e '/common.lib/ r common.lib' \
		-e '/common.label-and-env/ r common.label-and-env' \
		$< > $@

#
# cc65
#
cc65: cc65/Dockerfile
	$(DOCKER) build -t $(ORG)/cc65:latest \
	cc65

cc65.test: cc65
	echo "Not working now"

#
# pvsneslib
#
pvsneslib: pvsneslib/Dockerfile
	$(DOCKER) build -t $(ORG)/pvsneslib:latest \
	pvsneslib

pvsneslib.test: pvsneslib
	echo "Not working now"

#
# psn00bsdk
#
psn00bsdk: psn00bsdk/Dockerfile
	$(DOCKER) build -t $(ORG)/psn00bsdk:latest \
	psn00bsdk

psn00bsdk.test: psn00bsdk
	echo "Not working now"

#
# sgdk
#
sgdk: sgdk/Dockerfile
	$(DOCKER) build -t $(ORG)/sgdk:latest \
	sgdk

sgdk.test: sgdk
	echo "Not working now"
#	docker run --rm -v $(PWD)/sgdk/sample/sonic:/src $(ORG)/sgdk

#
# web-wasm
#
web-wasm: web-wasm/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	cp -r test web-wasm/
	$(DOCKER) build -t $(ORG)/web-wasm:latest \
		--build-arg IMAGE=$(ORG)/web-wasm \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		web-wasm
	$(DOCKER) build -t $(ORG)/web-wasm:$(TAG) \
		--build-arg IMAGE=$(ORG)/web-wasm \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		web-wasm
	rm -rf web-wasm/test
	rm -rf $@/imagefiles

web-wasm.test: web-wasm
	cp -r test web-wasm/
	$(DOCKER) run $(RM) $(ORG)/web-wasm > $(BIN)/dockcross-web-wasm && chmod +x $(BIN)/dockcross-web-wasm
	$(BIN)/dockcross-web-wasm python test/run.py --exe-suffix ".js"
	rm -rf web-wasm/test

#
# manylinux2014-aarch64
#
manylinux2014-aarch64: manylinux2014-aarch64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-aarch64:latest \
		--build-arg IMAGE=$(ORG)/manylinux2014-aarch64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-aarch64/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux2014-aarch64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-aarch64 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-aarch64/Dockerfile .
	rm -rf $@/imagefiles

manylinux2014-aarch64.test: manylinux2014-aarch64
	$(DOCKER) run $(RM) $(ORG)/manylinux2014-aarch64 > $(BIN)/dockcross-manylinux2014-aarch64 && chmod +x $(BIN)/dockcross-manylinux2014-aarch64
	$(BIN)/dockcross-manylinux2014-aarch64 /opt/python/cp38-cp38/bin/python test/run.py

#
# manylinux2014-x64
#
manylinux2014-x64: manylinux2014-x64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-x64:latest \
		--build-arg IMAGE=$(ORG)/manylinux2014-x64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x64/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux2014-x64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-x64 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x64/Dockerfile .
	rm -rf $@/imagefiles

manylinux2014-x64.test: manylinux2014-x64
	$(DOCKER) run $(RM) $(ORG)/manylinux2014-x64 > $(BIN)/dockcross-manylinux2014-x64 && chmod +x $(BIN)/dockcross-manylinux2014-x64
	$(BIN)/dockcross-manylinux2014-x64 /opt/python/cp38-cp38/bin/python test/run.py

#
# manylinux2014-x86
#
manylinux2014-x86: manylinux2014-x86/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-x86:latest \
		--build-arg IMAGE=$(ORG)/manylinux2014-x86 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x86/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux2014-x86:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-x86 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x86/Dockerfile .
	rm -rf $@/imagefiles

manylinux2014-x86.test: manylinux2014-x86
	$(DOCKER) run $(RM) $(ORG)/manylinux2014-x86 > $(BIN)/dockcross-manylinux2014-x86 && chmod +x $(BIN)/dockcross-manylinux2014-x86
	$(BIN)/dockcross-manylinux2014-x86 /opt/python/cp38-cp38/bin/python test/run.py

#
<<<<<<< HEAD
=======
# manylinux2010-x64
#

manylinux2010-x64: manylinux2010-x64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2010-x64:latest \
		--build-arg IMAGE=$(ORG)/manylinux2010-x64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2010-x64/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux2010-x64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2010-x64 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2010-x64/Dockerfile .
	rm -rf $@/imagefiles

manylinux2010-x64.test: manylinux2010-x64
	$(DOCKER) run $(RM) dockcross/manylinux2010-x64 > $(BIN)/dockcross-manylinux2010-x64 && chmod +x $(BIN)/dockcross-manylinux2010-x64
	$(BIN)/dockcross-manylinux2010-x64 /opt/python/cp38-cp38/bin/python test/run.py

#
# manylinux2010-x86
#

manylinux2010-x86: manylinux2010-x86/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2010-x86:latest \
		--build-arg IMAGE=$(ORG)/manylinux2010-x86 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2010-x86/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux2010-x86:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2010-x86 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2010-x86/Dockerfile .
	rm -rf $@/imagefiles

manylinux2010-x86.test: manylinux2010-x86
	$(DOCKER) run $(RM) $(ORG)/manylinux2010-x86 > $(BIN)/dockcross-manylinux2010-x86 && chmod +x $(BIN)/dockcross-manylinux2010-x86
	$(BIN)/dockcross-manylinux2010-x86 /opt/python/cp38-cp38/bin/python test/run.py

#
# manylinux1-x64
#

manylinux1-x64: manylinux1-x64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux1-x64:latest \
		--build-arg IMAGE=$(ORG)/manylinux1-x64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux1-x64/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux1-x64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux1-x64 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux1-x64/Dockerfile .
	rm -rf $@/imagefiles

manylinux1-x64.test: manylinux1-x64
	$(DOCKER) run $(RM) $(ORG)/manylinux1-x64 > $(BIN)/dockcross-manylinux1-x64 && chmod +x $(BIN)/dockcross-manylinux1-x64
	$(BIN)/dockcross-manylinux1-x64 /opt/python/cp38-cp38/bin/python test/run.py

#
# manylinux1-x86
#

manylinux1-x86: manylinux1-x86/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux1-x86:latest \
		--build-arg IMAGE=$(ORG)/manylinux1-x86 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux1-x86/Dockerfile .
	$(DOCKER) build -t $(ORG)/manylinux1-x86:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux1-x86 \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux1-x86/Dockerfile .
	rm -rf $@/imagefiles

manylinux1-x86.test: manylinux1-x86
	$(DOCKER) run $(RM) $(ORG)/manylinux1-x86 > $(BIN)/dockcross-manylinux1-x86 && chmod +x $(BIN)/dockcross-manylinux1-x86
	$(BIN)/dockcross-manylinux1-x86 /opt/python/cp38-cp38/bin/python test/run.py

#
>>>>>>> 9adf96c16b00759a9f7f69be3e61b5e16cdd6ac4
# base
#

base: Dockerfile imagefiles/
	$(DOCKER) build -t $(ORG)/base:latest \
		--build-arg IMAGE=$(ORG)/base \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		.
	$(DOCKER) build -t $(ORG)/base:$(TAG) \
		--build-arg IMAGE=$(ORG)/base \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		.

base.test: base
	$(DOCKER) run $(RM) $(ORG)/base > $(BIN)/dockcross-base && chmod +x $(BIN)/dockcross-base

#
# display
#
display_images:
	for image in $(IMAGES); do echo $$image; done

$(VERBOSE).SILENT: display_images

#
# build implicit rule
#
$(STANDARD_IMAGES): %: %/Dockerfile base
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/$@:latest \
		--build-arg IMAGE=$(ORG)/$@ \
		--build-arg DOCKER_IMAGE=$(ORG)/base:latest  \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$@
	$(DOCKER) build -t $(ORG)/$@:$(TAG) \
		--build-arg IMAGE=$(ORG)/$@ \
		--build-arg DOCKER_IMAGE=$(ORG)/base:latest  \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$@
	rm -rf $@/imagefiles

clean:
	for d in $(STANDARD_IMAGES) ; do rm -rf $$d/imagefiles ; done
	for d in $(GEN_IMAGE_DOCKERFILES) ; do rm -f $$d/Dockerfile ; done
	rm -f Dockerfile

#
# testing implicit rule
#
.SECONDEXPANSION:
$(addsuffix .test,$(STANDARD_IMAGES)): $$(basename $$@)
	$(DOCKER) run $(RM) $(ORG)/$(basename $@) > $(BIN)/dockcross-$(basename $@) && chmod +x $(BIN)/dockcross-$(basename $@)
<<<<<<< HEAD
	$(BIN)/dockcross-$(basename $@) python3 test/run.py $($@_ARGS)

.SECONDEXPANSION:
$(addsuffix .full,$(STANDARD_IMAGES)): %: %/Dockerfile $$(basename $$@)
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/$@:latest \
		--build-arg IMAGE=$(ORG)/$@ \
		--build-arg DOCKER_IMAGE=$(ORG)/$(patsubst %.full,%,$@):latest  \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$@
	$(DOCKER) build -t $(ORG)/$@:$(TAG) \
		--build-arg IMAGE=$(ORG)/$@ \
		--build-arg DOCKER_IMAGE=$(ORG)/$(patsubst %.full,%,$@):latest  \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$@
	rm -rf $@/imagefiles
=======
	$(BIN)/dockcross-$(basename $@) python test/run.py $($@_ARGS)
>>>>>>> 9adf96c16b00759a9f7f69be3e61b5e16cdd6ac4

#
# testing prerequisites implicit rule
#
test.prerequisites:
	mkdir -p $(BIN)

$(addsuffix .test,base $(IMAGES)): test.prerequisites

<<<<<<< HEAD
clean:
	for d in $(STANDARD_IMAGES) ; do rm -rf $$d/imagefiles ; done
	for d in $(GEN_IMAGE_DOCKERFILES) ; do rm -rf $$d/Dockerfile ; done
	rm -f Dockerfile

.PHONY: base images $(IMAGES) test %.test %.full clean
=======
.PHONY: base images $(IMAGES) test %.test clean
>>>>>>> 9adf96c16b00759a9f7f69be3e61b5e16cdd6ac4
