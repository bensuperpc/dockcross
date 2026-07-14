BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-xtensa-uclibc

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = ninja openssl cpython
OPENSSL_ARGS = linux-generic64 no-asm no-threads no-engine no-hw no-weak-ssl-ciphers no-dtls no-shared no-dso
CPYTHON_ARGS = --host=xtensa-fsf-linux-uclibc --target=xtensa-fsf-linux-uclibc
