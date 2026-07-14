# manylinux2014-x86 is FROM quay.io/pypa/manylinux2014_i686 directly (hardcoded in
# Dockerfile.in). BASE_IMAGE_* below is only informational to satisfy the guard.
BASE_IMAGE_REGISTRY ?= quay.io
BASE_IMAGE_PATH ?= pypa
BASE_IMAGE_NAME = manylinux2014_i686
BASE_IMAGE_TAG  = 2025-02-23-361da4c

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = manylinux2014-x86

# Dockerfile.in COPYs linux-x86/... and manylinux2014-x86/Toolchain.cmake, so the
# build context has to be the repository root, not this preset's own directory.
BUILD_CONTEXT_DIR = $(PRESET_DIR)

TEST_IMAGE_CMD = /opt/python/cp311-cp311/bin/python test/run.py
TEST_IMAGE_ARGS =

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja openssl SQLite fmt cpython
STOCKFISH_ARGS = ARCH=x86-32-sse41-popcnt
OPENSSL_ARGS = linux-x86

# FROM an external upstream image, not our own base - opt out of the
# Makefile's "DEPENDS_ON = base.build" default.
DEPENDS_ON =
