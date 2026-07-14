# manylinux_2_34-x64 is FROM quay.io/pypa/manylinux_2_34_x86_64 directly (hardcoded
# in Dockerfile.in). BASE_IMAGE_* below is only informational to satisfy the guard.
BASE_IMAGE_REGISTRY ?= quay.io
BASE_IMAGE_PATH ?= pypa
BASE_IMAGE_NAME = manylinux_2_34_x86_64
BASE_IMAGE_TAG  = 2025-02-02-9ae4a5a

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = manylinux_2_34-x64

# Dockerfile.in COPYs linux-x64/... and manylinux_2_34-x64/Toolchain.cmake, so the
# build context has to be the repository root, not this preset's own directory.
BUILD_CONTEXT_DIR = $(PRESET_DIR)

TEST_IMAGE_CMD = /opt/python/cp310-cp310/bin/python test/run.py
TEST_IMAGE_ARGS =

# FROM an external upstream image, not our own base - opt out of the
# Makefile's "DEPENDS_ON = base.build" default.
DEPENDS_ON =
