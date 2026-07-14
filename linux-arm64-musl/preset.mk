BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-arm64-musl

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja openssl C SQLite fmt cpython
STOCKFISH_ARGS = ARCH=armv8
OPENSSL_ARGS = linux-aarch64
CPYTHON_ARGS = --host=aarch64-linux-musl --target=aarch64-linux-musl
