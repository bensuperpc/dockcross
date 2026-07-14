# web-wasm is FROM emscripten/emsdk:<version><arch-tag> directly (upstream image,
# not our own base). The arch-tag ("" for amd64, "-arm64" for arm64) is required
# because emscripten/emsdk does not publish a single multi-arch manifest.
BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= emscripten
BASE_IMAGE_NAME = emsdk
BASE_IMAGE_TAG  = 5.0.1

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = web-wasm

EMSCRIPTEN_HOST_ARCH_TAG = $(if $(filter arm64,$(HOST_ARCH)),-arm64,)
EXTRA_BUILD_ARGS = --build-arg HOST_ARCH_TAG=$(EMSCRIPTEN_HOST_ARCH_TAG)

TEST_IMAGE_CMD = python test/run.py
TEST_IMAGE_ARGS = --exe-suffix ".js"

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = SQLite
RAYLIB_ARGS = -DPLATFORM=Web

# FROM an external upstream image, not our own base - opt out of the
# Makefile's "DEPENDS_ON = base.build" default.
DEPENDS_ON =
