BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-armv5

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = ninja openssl SQLite fmt cpython
OPENSSL_ARGS = linux-armv4
CPYTHON_ARGS = --host=armv5-unknown-linux-gnueabi --target=armv5-unknown-linux-gnueabi
