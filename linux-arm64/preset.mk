BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-arm64

TEST_IMAGE_CMD =
TEST_IMAGE_ARGS =
RUN_IMAGE_CMD  =
RUN_IMAGE_ARGS =

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja C SQLite llama_cpp fmt cpython
STOCKFISH_ARGS = ARCH=armv8
CPYTHON_ARGS = --host=aarch64-unknown-linux-gnu --target=aarch64-unknown-linux-gnu
