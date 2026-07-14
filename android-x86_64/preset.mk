BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = android-x86_64

STATIC_DOCKERFILE = yes

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = stockfish openssl SQLite
STOCKFISH_ARGS = ARCH=x86-64 COMP=ndk
OPENSSL_ARGS = android-x86_64 no-shared
