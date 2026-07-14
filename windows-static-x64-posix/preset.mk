BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = windows-static-x64-posix

TEST_IMAGE_ARGS = --exe-suffix ".exe"

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish fmt
STOCKFISH_ARGS = ARCH=x86-64-modern COMP=mingw
