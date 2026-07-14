BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-ppc64le

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja openssl C SQLite llama_cpp fmt cpython
STOCKFISH_ARGS = ARCH=ppc-64
OPENSSL_ARGS = linux-ppc64le
CPYTHON_ARGS = --host=powerpc64le-unknown-linux-gnu --target=powerpc64le-unknown-linux-gnu
