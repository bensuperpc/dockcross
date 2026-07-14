BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-i686

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = ninja openssl C SQLite fmt cpython
OPENSSL_ARGS = linux-generic32
CPYTHON_ARGS = --host=i686-linux-gnu --target=i686-linux-gnu
