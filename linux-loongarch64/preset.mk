BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-loongarch64

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja openssl C fmt cpython
STOCKFISH_ARGS = ARCH=loongarch64
OPENSSL_ARGS = linux64-loongarch64
C_ARGS = -DCMAKE_C_FLAGS=-Wno-incompatible-pointer-types
CPYTHON_ARGS = --host=loongarch64-unknown-linux-gnu --target=loongarch64-unknown-linux-gnu
