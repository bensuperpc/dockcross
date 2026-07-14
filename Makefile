# ==============================================================================
# Preset detection
# ==============================================================================
PRESET_DIR       ?= .

HOST_ARCH        := $(or $(HOST_ARCH), $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/'))

preset-path = $(if $(filter base,$(1)),$(PRESET_DIR),$(PRESET_DIR)/$(1))

build-context-dir = $(if $(BUILD_CONTEXT_DIR),$(BUILD_CONTEXT_DIR),$(call preset-path,$(1)))

PRESET_FILES := $(shell find $(PRESET_DIR) -name .git -prune -o -mindepth 2 -name "preset.mk" -print)
ALL_PRESETS  := base $(patsubst $(PRESET_DIR)/%/preset.mk,%,$(PRESET_FILES))

CURRENT_TARGET_NAME := $(firstword $(MAKECMDGOALS))

POSSIBLE_PRESET := $(basename $(CURRENT_TARGET_NAME))

ifeq ($(POSSIBLE_PRESET),base)
    -include $(PRESET_DIR)/preset.mk
else ifneq ($(wildcard $(PRESET_DIR)/$(POSSIBLE_PRESET)/preset.mk),)
    include $(PRESET_DIR)/$(POSSIBLE_PRESET)/preset.mk
endif

# ==============================================================================
# Main config Makefile for Docker SDK Images
# ==============================================================================
AUTHOR         ?= dockcross
WEB_SITE       ?= dockcross.org

# Registries
BASE_IMAGE_REGISTRY   ?= docker.io
BASE_IMAGE_PATH       ?=
OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH     ?= dockcross

# Docker Config
DOCKER_EXEC      ?= docker
PROGRESS_OUTPUT  ?= plain

PUSH_ON_BUILD ?= false
ifeq ($(PUSH_ON_BUILD),true)
	DOCKER_DRIVER := --push
	BUILD_IMAGE_ARGS += --sbom=true --provenance=true
	BUILD_IMAGE_ARGS += --cache-from=type=registry,ref=$(OUTPUT_IMAGE_FINAL):cache
	BUILD_IMAGE_ARGS += --cache-to=type=registry,ref=$(OUTPUT_IMAGE_FINAL):cache,mode=max
else
	DOCKER_DRIVER := --load
endif

ARCH_LIST        ?= linux/$(HOST_ARCH)
PLATFORMS        ?= $(subst $(space),$(comma),$(strip $(ARCH_LIST)))
TMPFS_SIZE       ?= 4g

DOCKER_BUILD_NETWORK ?= host

# Folders
COMMON_DIR       ?= common
BIN_DIR          ?= ./bin
TEST_SCRATCH_DIR ?= ./.dockcross-test-cache

EXTRA_TESTS ?=

ORG ?= $(OUTPUT_IMAGE_REGISTRY)/$(OUTPUT_IMAGE_PATH)

DOCKER_COMPOSITE_SOURCES = common.docker common.debian \
    common.manylinux2014 common.manylinux_2_28 common.manylinux_2_34 \
    common.buildroot common.crosstool common.webassembly common.windows \
    common-manylinux.crosstool common-manylinux_2_28.crosstool common-manylinux_2_34.crosstool \
    common.dockcross common.label-and-env

# RUN/TEST
TEST_IMAGE_CMD  ?= python3 test/run.py
TEST_IMAGE_ARGS ?=
RUN_IMAGE_CMD   ?= /bin/bash
RUN_IMAGE_ARGS  ?=

BUILD_CONTEXT_DIR ?=
STATIC_DOCKERFILE ?= no
DEPENDS_ON        ?= base.build
EXTRA_BUILD_ARGS  ?=

BIND_HOST_DIR := $(shell pwd)
BIND_CONTAINER_DIR ?= /work
WORKDIR ?= /work

# Automatic variables
CURRENT_USER := $(shell whoami)
UID := $(shell id -u ${CURRENT_USER})
GID := $(shell id -g ${CURRENT_USER})
CURRENT_GROUP := $(shell id -gn ${CURRENT_USER})

BUILDER_ENV := -e BUILDER_UID=$(UID) -e BUILDER_GID=$(GID) -e BUILDER_USER=$(CURRENT_USER) -e BUILDER_GROUP=$(CURRENT_GROUP)
DATE           := $(shell date -u +"%Y%m%d")
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo nogit)
GIT_ORIGIN := $(shell git config --get remote.origin.url 2>/dev/null || echo unknown)
UUID           := $(shell uuidgen)

TRIVY_IMAGE    ?= aquasec/trivy:0.68.2
HADOLINT_IMAGE ?= hadolint/hadolint:v2.14.0
SHELLCHECK_IMAGE ?= koalaman/shellcheck:stable

# Tag images with date and Git short hash, mirroring the historical dockcross tagging scheme
TAG := $(DATE)-$(GIT_SHA)

comma := ,
space := $(subst ,, )

# ==============================================================================
# Presets logic
# ==============================================================================

PRESET_TARGETS := all help build test push pull generate scan lint update clean run inspect sbom script \
	rebuild sign history cache check prepare-imagefiles test-extra
.PHONY: $(ALL_PRESETS)

.DEFAULT_GOAL := list

define BIND_PRESET_DEPENDENCIES
  $(1).test:     $(1).build
  $(1).run:      $(1).build
  $(1).push:     $(1).test
  $(1).scan:     $(1).build
  $(1).lint:     $(1).generate
  $(1).sbom:     $(1).build
  $(1).inspect:  $(1).build
  $(1).history:  $(1).build
  $(1).script:   $(1).build
endef

$(foreach p,$(ALL_PRESETS),$(eval $(call BIND_PRESET_DEPENDENCIES,$(p))))

# Generate final image names
ifeq ($(strip $(BASE_IMAGE_PATH)),)
    BASE_IMAGE_FINAL := $(BASE_IMAGE_REGISTRY)/$(BASE_IMAGE_NAME)
else
    BASE_IMAGE_FINAL := $(BASE_IMAGE_REGISTRY)/$(BASE_IMAGE_PATH)/$(BASE_IMAGE_NAME)
endif

OUTPUT_IMAGE_FINAL := $(ORG)/$(OUTPUT_IMAGE_NAME)

# ==============================================================================
# Mandatory variables check
# ==============================================================================
MANDATORY_VARS = BASE_IMAGE_NAME BASE_IMAGE_TAG OUTPUT_IMAGE_NAME OUTPUT_IMAGE_REGISTRY \
	OUTPUT_IMAGE_PATH BASE_IMAGE_REGISTRY

# ==============================================================================
# Useful functions
# ==============================================================================
define docker-tags
	$(OUTPUT_IMAGE_FINAL):latest \
	$(OUTPUT_IMAGE_FINAL):latest-$(HOST_ARCH) \
	$(OUTPUT_IMAGE_FINAL):$(TAG)
endef

define docker-push-tags
	$(OUTPUT_IMAGE_FINAL):latest \
	$(OUTPUT_IMAGE_FINAL):$(TAG)
endef

define docker-run-cmd
	$(DOCKER_EXEC) run --rm $(1) $(BUILDER_ENV) \
		--security-opt no-new-privileges \
		--mount type=bind,source=$(BIND_HOST_DIR),target=$(BIND_CONTAINER_DIR) \
		--workdir $(WORKDIR) \
		--mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=$(TMPFS_SIZE) \
		--platform $(firstword $(ARCH_LIST)) \
		--name $(OUTPUT_IMAGE_NAME)-$(UUID) \
		$(OUTPUT_IMAGE_FINAL):latest $(2) $(3)
endef

define extra-test-run
	$(DOCKER_EXEC) run --rm $(BUILDER_ENV) \
		--mount type=bind,source=$(abspath $(TEST_SCRATCH_DIR)/$(1)),target=/work \
		--workdir /work \
		--platform $(firstword $(ARCH_LIST)) \
		$(OUTPUT_IMAGE_FINAL):latest bash -c "$(2)"
endef

# ==============================================================================
# Preset targets
# ==============================================================================

.PHONY: %.all %.generate %.build %.test %.run %.push %.pull %.scan %.clean %.prune %.update %.lint %.inspect %.sbom %.script %.prepare-imagefiles \
	%.rebuild %.sign %.history %.cache %.check %.test-extra \
	%.test-stockfish %.test-ninja %.test-openssl %.test-C %.test-SQLite %.test-llama_cpp \
	%.test-fmt %.test-cpython %.test-raylib %.test-mbedtls %.test-libopencm3

$(ALL_PRESETS): %: %.build

%.all: %.update %.generate %.build %.test %.check %.push ;

.PHONY: %.guard
%.guard:
	$(foreach v,$(MANDATORY_VARS), \
	  $(if $(strip $($(v))),, \
	    $(error Missing mandatory var: $(v) (preset=$*))))

%.generate: %.guard %.clean
ifeq ($(STATIC_DOCKERFILE),yes)
	@test -f $(call preset-path,$*)/Dockerfile || \
	  (echo "Missing committed Dockerfile for $* (STATIC_DOCKERFILE=yes)" && exit 1)
else
	@echo ">>> Generating Dockerfile for $*"
	@sed $(foreach f,$(DOCKER_COMPOSITE_SOURCES),\
		-e '/$(f)/ r $(COMMON_DIR)/$(f)') \
		$(call preset-path,$*)/Dockerfile.in > $(call preset-path,$*)/Dockerfile
endif

%.prepare-imagefiles:
	@ctx="$(call build-context-dir,$*)"; \
	if [ "$$ctx" != "$(PRESET_DIR)" ]; then \
	  mkdir -p "$$ctx/imagefiles" && cp -r $(PRESET_DIR)/imagefiles/. "$$ctx/imagefiles/"; \
	fi

%.build: %.generate %.prepare-imagefiles
	@$(DOCKER_EXEC) image inspect $(BASE_IMAGE_FINAL):$(BASE_IMAGE_TAG) >/dev/null 2>&1 || \
		{ $(foreach d,$(DEPENDS_ON),$(MAKE) $(d);) true; }
	$(DOCKER_EXEC) buildx build $(call build-context-dir,$*) \
		--file $(call preset-path,$*)/Dockerfile \
		--network $(DOCKER_BUILD_NETWORK) \
		--platform $(PLATFORMS) --progress $(PROGRESS_OUTPUT) \
		$(foreach tag,$(call docker-tags),--tag $(tag)) \
		--build-arg BUILD_DATE=$(DATE) \
		--build-arg ORG=$(ORG) \
		--build-arg HOST_ARCH=$(HOST_ARCH) \
		--build-arg IMAGE=$(ORG)/$(OUTPUT_IMAGE_NAME) \
		--build-arg VERSION=$(TAG) \
		--build-arg VCS_REF=$(GIT_SHA) \
		--build-arg VCS_URL=$(GIT_ORIGIN) \
		--build-arg AUTHOR=$(AUTHOR) \
		--build-arg URL=$(WEB_SITE) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_FINAL):$(BASE_IMAGE_TAG) \
		--build-arg BASE_IMAGE_NAME=$(BASE_IMAGE_NAME) \
		--build-arg BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
		$(EXTRA_BUILD_ARGS) \
		$(BUILD_IMAGE_ARGS) $(DOCKER_DRIVER)

%.script: %.build
	@mkdir -p $(BIN_DIR)
	$(DOCKER_EXEC) run --rm $(OUTPUT_IMAGE_FINAL):latest > $(BIN_DIR)/dockcross-$* && chmod +x $(BIN_DIR)/dockcross-$*

%.test: %.build %.script
	$(call docker-run-cmd,,$(TEST_IMAGE_CMD),$(TEST_IMAGE_ARGS))

%.run: %.build
	$(call docker-run-cmd,-it,$(RUN_IMAGE_CMD),$(RUN_IMAGE_ARGS))

# ==============================================================================
# Extra tests
# ==============================================================================

%.test-extra: %.build
	@$(foreach t,$(EXTRA_TESTS),$(MAKE) $*.test-$(t);)

%.test-stockfish: %.build
	rm -rf $(TEST_SCRATCH_DIR)/stockfish
	git clone --depth 1 --branch sf_17.1 https://github.com/official-stockfish/Stockfish.git $(TEST_SCRATCH_DIR)/stockfish
	$(call extra-test-run,stockfish,make -C src net && make -C src build $(STOCKFISH_ARGS) -j$$(nproc))
	rm -rf $(TEST_SCRATCH_DIR)/stockfish

%.test-ninja: %.build
	rm -rf $(TEST_SCRATCH_DIR)/ninja
	git clone --depth 1 --branch v1.11.1 https://github.com/ninja-build/ninja.git $(TEST_SCRATCH_DIR)/ninja
	$(call extra-test-run,ninja,cmake -Bbuild -S. -GNinja $(NINJA_ARGS) && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/ninja

%.test-openssl: %.build
	rm -rf $(TEST_SCRATCH_DIR)/openssl
	git clone --depth 1 --branch OpenSSL_1_1_1w https://github.com/openssl/openssl.git $(TEST_SCRATCH_DIR)/openssl
	cd $(TEST_SCRATCH_DIR)/openssl && \
	  wget -q https://raw.githubusercontent.com/mavlink/MAVSDK/17ad598f0e004d225f5e939aa2947a95791f2f9b/cpp/third_party/openssl/dockcross-android.patch && \
	  patch -p0 < dockcross-android.patch
	$(call extra-test-run,openssl,./Configure $(OPENSSL_ARGS) && make -j$$(nproc))
	rm -rf $(TEST_SCRATCH_DIR)/openssl

%.test-C: %.build
	rm -rf $(TEST_SCRATCH_DIR)/C
	git clone https://github.com/TheAlgorithms/C.git $(TEST_SCRATCH_DIR)/C
	cd $(TEST_SCRATCH_DIR)/C && git checkout b0a41bb38c67ddebb31d3fe06d11e171410c3379
	$(call extra-test-run,C,cmake -Bbuild -S. -GNinja $(C_ARGS) && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/C

%.test-SQLite: %.build
	rm -rf $(TEST_SCRATCH_DIR)/sqlite
	git clone https://github.com/sqlite/sqlite.git $(TEST_SCRATCH_DIR)/sqlite
	cd $(TEST_SCRATCH_DIR)/sqlite && git checkout 1cf61ce636915a5e92d4aa883755cee258aa98d6
	$(call extra-test-run,sqlite,./configure $(SQLITE_ARGS) && make -j$$(nproc) sqlite3 sqlite3.c sqldiff)
	rm -rf $(TEST_SCRATCH_DIR)/sqlite

%.test-llama_cpp: %.build
	rm -rf $(TEST_SCRATCH_DIR)/llama.cpp
	git clone https://github.com/ggerganov/llama.cpp.git $(TEST_SCRATCH_DIR)/llama.cpp
	cd $(TEST_SCRATCH_DIR)/llama.cpp && git checkout 76614f352e94d25659306d9e97321f204e5de0d3
	$(call extra-test-run,llama.cpp,cmake -Bbuild -S. -GNinja $(LLAMA_CPP_ARGS) && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/llama.cpp

%.test-fmt: %.build
	rm -rf $(TEST_SCRATCH_DIR)/fmt
	git clone --depth 1 --branch 9.1.0 https://github.com/fmtlib/fmt.git $(TEST_SCRATCH_DIR)/fmt
	$(call extra-test-run,fmt,cmake -Bbuild -S. -GNinja $(FMT_ARGS) -DFMT_DOC=OFF && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/fmt

%.test-cpython: %.build
	rm -rf $(TEST_SCRATCH_DIR)/cpython
	git clone --depth 1 --branch v3.11.2 https://github.com/python/cpython.git $(TEST_SCRATCH_DIR)/cpython
	$(call extra-test-run,cpython,./configure ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no --disable-ipv6 $(CPYTHON_ARGS) --build=x86_64-linux-gnu --with-build-python --enable-shared && make -j$$(nproc))
	rm -rf $(TEST_SCRATCH_DIR)/cpython

%.test-raylib: %.build
	rm -rf $(TEST_SCRATCH_DIR)/raylib
	git clone https://github.com/raysan5/raylib.git $(TEST_SCRATCH_DIR)/raylib
	cd $(TEST_SCRATCH_DIR)/raylib && git checkout a12ddacb7bfbc6e552e6145456f2fe6dfdfbe1c7
	$(call extra-test-run,raylib,cmake -Bbuild -S. -GNinja $(RAYLIB_ARGS) && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/raylib

%.test-mbedtls: %.build
	rm -rf $(TEST_SCRATCH_DIR)/mbedtls
	git clone --depth 1 --branch archive/baremetal https://github.com/Mbed-TLS/mbedtls.git $(TEST_SCRATCH_DIR)/mbedtls
	$(call extra-test-run,mbedtls,scripts/config.pl baremetal && cmake -Bbuild -S. -GNinja $(MBEDTLS_ARGS) && cmake --build build)
	rm -rf $(TEST_SCRATCH_DIR)/mbedtls

%.test-libopencm3: %.build
	rm -rf $(TEST_SCRATCH_DIR)/libopencm3
	git clone https://github.com/libopencm3/libopencm3.git $(TEST_SCRATCH_DIR)/libopencm3
	cd $(TEST_SCRATCH_DIR)/libopencm3 && git checkout 467522778329d6f41781a6c951b77d6ff6744de6
	$(call extra-test-run,libopencm3,make $(LIBOPENCM3_ARGS) -j$$(nproc))
	rm -rf $(TEST_SCRATCH_DIR)/libopencm3

%.push: %.test
	$(foreach tag,$(call docker-push-tags),$(DOCKER_EXEC) push $(tag) &&) true

%.pull:
	$(foreach tag,$(call docker-push-tags),$(DOCKER_EXEC) pull $(tag) &&) true

%.update:
	@echo ">>> Updating base image for $*"
	$(DOCKER_EXEC) pull $(BASE_IMAGE_FINAL):$(BASE_IMAGE_TAG)

%.clean:
	@echo "Cleaning generated Dockerfile for $*"
ifneq ($(STATIC_DOCKERFILE),yes)
	@rm -f $(call preset-path,$*)/Dockerfile
endif
	@ctx="$(call build-context-dir,$*)"; \
	if [ "$$ctx" != "$(PRESET_DIR)" ]; then rm -rf "$$ctx/imagefiles"; fi

%.prune: %.clean
	$(DOCKER_EXEC) builder prune -f --filter name=$(OUTPUT_IMAGE_FINAL)

%.inspect:
	$(DOCKER_EXEC) image inspect \
		$(OUTPUT_IMAGE_FINAL):latest

%.rebuild:
	$(MAKE) $*.clean
	$(MAKE) $*.build BUILD_IMAGE_ARGS="--no-cache"

%.history:
	$(DOCKER_EXEC) history \
	  $(OUTPUT_IMAGE_FINAL):latest

%.sbom:
	syft $(OUTPUT_IMAGE_FINAL):latest -o spdx-json > $*.sbom.json

%.sign:
	cosign sign $(OUTPUT_IMAGE_FINAL):latest

%.scan:
	$(DOCKER_EXEC) run --rm \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  $(TRIVY_IMAGE) \
	  image --severity HIGH,CRITICAL \
	  $(OUTPUT_IMAGE_FINAL):latest

%.lint: %.generate
	$(DOCKER_EXEC) run --rm -i $(HADOLINT_IMAGE) < $(call preset-path,$*)/Dockerfile

%.check: %.lint %.scan %.sbom

%.cache:
	$(DOCKER_EXEC) buildx imagetools inspect $(OUTPUT_IMAGE_FINAL):cache

# ==============================================================================
# Global targets
# ==============================================================================
.PHONY: $(PRESET_TARGETS) clean purge list display_images bash-check

%-all:
	@$(foreach p,$(ALL_PRESETS),$(MAKE) $(p).$* &&) true

list:
	@echo "Available presets:"
	@$(foreach p,$(ALL_PRESETS),echo " - $(p)";)

display_images:
	@$(foreach p,$(filter-out base,$(ALL_PRESETS)),echo $(p);)

$(VERBOSE).SILENT: display_images

clean:
	@$(foreach p,$(ALL_PRESETS),$(MAKE) $(p).clean &&) true
	@rm -rf $(BIN_DIR)

purge: clean
	$(DOCKER_EXEC) images --filter='reference=$(ORG)/*' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER_EXEC) rmi -f
	$(DOCKER_EXEC) builder prune -f

bash-check:
	find . -type f \( -name "*.sh" -o -name "*.bash" \) -print0 | xargs -0 -P"$(shell nproc)" -I{} \
	  $(DOCKER_EXEC) run --rm -v "$(PWD)":/mnt -w /mnt $(SHELLCHECK_IMAGE) --check-sourced --color=auto --format=gcc --severity=warning --shell=bash --enable=all "{}"

docker-container-builder:
	$(DOCKER_EXEC) buildx create --name mybuilder --use
	$(DOCKER_EXEC) buildx inspect --bootstrap
	$(DOCKER_EXEC) buildx inspect mybuilder

docker-default-builder:
	$(DOCKER_EXEC) buildx use default
