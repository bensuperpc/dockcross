BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-ppc

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = ninja openssl C SQLite llama_cpp fmt cpython
OPENSSL_ARGS = linux-ppc
CPYTHON_ARGS = --host=powerpc-unknown-linux-gnu --target=powerpc-unknown-linux-gnu
