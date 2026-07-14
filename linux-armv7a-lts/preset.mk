BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-armv7a-lts

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish ninja openssl SQLite fmt cpython
STOCKFISH_ARGS = ARCH=armv7-neon
OPENSSL_ARGS = linux-armv4
CPYTHON_ARGS = --host=arm-cortexa8_neon-linux-gnueabihf --target=arm-cortexa8_neon-linux-gnueabihf
