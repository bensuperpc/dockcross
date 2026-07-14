# web-wasi-threads is FROM ${ORG}/web-wasi:latest (wasm threading proposal layered
# on top of web-wasi), so web-wasi has to be built first.
BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?=
BASE_IMAGE_NAME = web-wasi
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = web-wasi-threads

DEPENDS_ON = web-wasi.build
