# Preset for the "base" image, built from the repository root Dockerfile.in.
# Every other preset is built FROM ${ORG}/base:latest.

BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?=
BASE_IMAGE_NAME = debian
BASE_IMAGE_TAG  = bookworm-slim

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = base

TEST_IMAGE_CMD = true
TEST_IMAGE_ARGS =
RUN_IMAGE_CMD  = /bin/bash
RUN_IMAGE_ARGS =

# Not FROM itself - opt out of the Makefile's "DEPENDS_ON = base.build" default.
DEPENDS_ON =
