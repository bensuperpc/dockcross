# manylinux_2_34-aarch64 is FROM ${ORG}/manylinux_2_34-x64:latest (cross toolchain
# layered on top of the x64 manylinux image, so it can run on an x86_64 host).
BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?=
BASE_IMAGE_NAME = manylinux_2_34-x64
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = manylinux_2_34-aarch64

# Dockerfile.in ADDs manylinux_2_34-aarch64/xc_script and COPYs
# manylinux_2_34-aarch64/Toolchain.cmake, so the build context has to be the
# repository root, not this preset's own directory.
BUILD_CONTEXT_DIR = $(PRESET_DIR)

DEPENDS_ON = manylinux_2_34-x64.build

TEST_IMAGE_CMD = /opt/python/cp310-cp310/bin/python test/run.py
TEST_IMAGE_ARGS =

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = openssl SQLite cpython
OPENSSL_ARGS = linux-aarch64
CPYTHON_ARGS = --host=aarch64-unknown-linux-gnu --target=aarch64-unknown-linux-gnu
