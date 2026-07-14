# Contributing

## Getting started

## How to add a new image ? (With crosstool-ng)

In this part, we will see how to add a new image, we will take example with `linux-arm64` for a raspberry pi 4, with [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng).

### Build and config crosstool-ng

To start, you need to download the source code of crosstool-ng:

```bash
git clone --recurse-submodules --remote-submodules https://github.com/crosstool-ng/crosstool-ng.git
```

Go to crosstool-ng folder:

```bash
cd crosstool-ng
```

Change git branch:

```bash
git checkout crosstool-ng-1.27.0
```

Once in the **crosstool-ng** folder, you must first run the `bootstrap` script:

```bash
./bootstrap
```

Then run the `configure` script:

*Note: `-enable-local` does a portable install of crosstool-ng.*:

```bash
./configure --enable-local
```

Finally, launch the building of crosstool-ng:

```bash
make -j$(nproc)
```

Once the crosstool-ng build is complete, you can run this command to test crosstool-ng:

```bash
./ct-ng --version
```

Before starting the configuration of the toolchains, i recommend you to use one of the examples from crosstool-ng and then make your changes, the command to display the examples:

```bash
./ct-ng list-samples
```

We will take the example of `aarch64-rpi4-linux-gnu`, a `.config` file will be created:

```bash
./ct-ng aarch64-rpi4-linux-gnu
```

*Alternatively*, we could copy an existing `crosstool-ng.config` from one of the target folders in the `dockcross` project to the local `.config`:

```bash
cp path/to/dockcross/linux-arm64/crosstool-ng.config .config
```

We will configure the toolchains according to our needs:

```bash
./ct-ng menuconfig
```

Once the modifications are made, we will display the name of the toolchains, it will be useful later:

```bash
./ct-ng show-tuple
```

### Configuring docker image

You must create a file with the **same** name of the docker image (`linux-arm64`).

Copy the `.config` of crosstool-ng to this file (`linux-arm64`) and rename it to `crosstool-ng.config`.

You need to create a file named `Toolchain.cmake` in `linux-arm64`.

Copy text to `Toolchain.cmake` file:

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR ARM64)

set(cross_triple $ENV{CROSS_TRIPLE})
set(cross_root $ENV{CROSS_ROOT})

set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})
set(CMAKE_Fortran_COMPILER $ENV{FC})

set(CMAKE_CXX_FLAGS "-I ${cross_root}/include/")

list(APPEND CMAKE_FIND_ROOT_PATH ${CMAKE_PREFIX_PATH} ${cross_root} ${cross_root}/${cross_triple})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_SYSROOT ${cross_root}/${cross_triple}/sysroot)

set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-arm64)
```

Then you must change these lines according to the targeted architecture, here **ARM64**:

```cmake
set(CMAKE_SYSTEM_PROCESSOR ARM64)
set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-arm64)
```

Then you must create a file named `Dockerfile.in` in the image folder (`linux-arm64`).

Copy text to `Dockerfile.in` file:

```docker
ARG ORG=dockcross
FROM ${ORG}/base:latest

LABEL maintainer="Matt McCormick matt@mmmccormick.com"

# This is for 64-bit ARM Linux machine

# Crosstool-ng crosstool-ng-1.25.0 2022-05-13
ENV CT_VERSION=crosstool-ng-1.25.0

#include "common.crosstool"

# The cross-compiling emulator
RUN apt-get update \
&& apt-get install -y \
  qemu-user \
  qemu-user-static \
&& apt-get clean --yes

# The CROSS_TRIPLE is a configured alias of the "aarch64-unknown-linux-gnu" target.
ENV CROSS_TRIPLE=aarch64-unknown-linux-gnu

ENV CROSS_ROOT=${XCC_PREFIX}/${CROSS_TRIPLE}
ENV AS=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-as \
    AR=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar \
    CC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gcc \
    CPP=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-cpp \
    CXX=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-g++ \
    LD=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ld \
    FC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gfortran

ENV QEMU_LD_PREFIX="${CROSS_ROOT}/${CROSS_TRIPLE}/sysroot"
ENV QEMU_SET_ENV="LD_LIBRARY_PATH=${CROSS_ROOT}/lib:${QEMU_LD_PREFIX}"

COPY Toolchain.cmake ${CROSS_ROOT}/
ENV CMAKE_TOOLCHAIN_FILE=${CROSS_ROOT}/Toolchain.cmake

ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig

# Linux kernel cross compilation variables
ENV PATH=${PATH}:${CROSS_ROOT}/bin
ENV CROSS_COMPILE=${CROSS_TRIPLE}-
ENV ARCH=arm64

#include "common.label-and-env"
```

Then you must change these lines according to the targeted architecture.

Here you have to change the value according to the name of the toolchain (./ct-ng show-tuple):

```docker
ENV CROSS_TRIPLE=aarch64-unknown-linux-gnu
```

These lines also need to be changed:

```docker
LABEL maintainer="Matt McCormick matt@mmmccormick.com"
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV ARCH=arm64
```

Once this part is finished, there must be 3 files in the `linux-arm64` folder:

- **`crosstool-ng.config`**, the configuration of the toolchain/crosstool-ng.
- **`Dockerfile.in`**, the docker file.
- **`Toolchain.cmake`**, the CMake file for the toolchains.

### Makefile

The [Makefile](Makefile) is generic: it knows how to generate/build/test/push
an image out of a "preset" directory, but it has no built-in knowledge of the
actual list of dockcross images. Every image folder is a preset that is
auto-discovered because it contains a `preset.mk` file - there is no central
list to edit anymore.

To add the image to the build system, create **`linux-arm64/preset.mk`**:

```make
BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = linux-arm64
```

`BASE_IMAGE_NAME = base` / `BASE_IMAGE_TAG = latest` matches the common case
where `Dockerfile.in` starts with `ARG ORG=dockcross` / `FROM ${ORG}/base:latest`
(the image is built on top of the local `base` preset). `OUTPUT_IMAGE_NAME`
should match the folder name so the built image is tagged
`<registry>/<path>/linux-arm64`.

A `preset.mk` can override or add anything the generic Makefile doesn't
already do the right thing for, for example:

- `TEST_IMAGE_CMD` / `TEST_IMAGE_ARGS`: override the command run by `make
  <image>.test` (defaults to `python3 test/run.py`). E.g. an image that only
  supports C needs `TEST_IMAGE_ARGS = --languages C`.
- `BUILD_CONTEXT_DIR`: override the docker build context directory. Defaults
  to the preset's own folder; a few images (the manylinux\*-aarch64/x64/x86
  family) `COPY` files from sibling folders and need
  `BUILD_CONTEXT_DIR = $(PRESET_DIR)` (the repository root) instead.
- `DEPENDS_ON`: list of `<preset>.build` targets that must be built first,
  for images whose `Dockerfile.in` is `FROM ${ORG}/<other-image>:latest`
  (e.g. `manylinux2014-aarch64` depends on `manylinux2014-x64`).
- `EXTRA_BUILD_ARGS`: extra `--build-arg KEY=VALUE` flags.
- `STATIC_DOCKERFILE = yes`: for the rare image that ships a committed
  `Dockerfile` instead of a generated `Dockerfile.in`.

See [linux-arm64/preset.mk](linux-arm64/preset.mk) and, for the more
involved cases, [manylinux2014-aarch64/preset.mk](manylinux2014-aarch64/preset.mk)
or [web-wasm/preset.mk](web-wasm/preset.mk).

### Image building and testing

You can now start building the image:

```bash
make linux-arm64
```

When finished, you can test it:

```bash
make linux-arm64.test
```

If you want to go a little further in the tests:

```bash
docker run --rm linux-arm64 > ./linux-arm64
chmod +x ./linux-arm64
```

And then run the commands to build a project (you must be in the directory of your project to build):

```bash
./linux-arm64 make
```

With CMake + Ninja:

```bash
./linux-arm64 cmake -Bbuild -S. -GNinja
./linux-arm64 ninja -Cbuild
```

### CI (github action)

To finish, you have to add the image/folder name to the `images` job's matrix
in `.github/workflows/main.yml`:

```yml
          # Linux arm64/armv8 images
          - { image: "linux-arm64", multiarch: "yes" }
```

`multiarch: "yes"` is only for the handful of images that are natively built
and published for both amd64 and arm64 (see `deploy-multi-arch-images` in the
same file); everything else should leave it empty.

That's the only thing the CI workflow needs to know. It builds the image with
`make <image>`, runs the fast in-container smoke test with `make
<image>.test`, and then `make <image>.test-extra` - which builds a handful of
real upstream projects (Stockfish, CMake, OpenSSL, CPython, ...) with the
image's toolchain. Which of those extra tests apply to this image and their
architecture-specific flags are **not** set in the workflow: they belong in
the image's own `preset.mk`, e.g.:

```make
EXTRA_TESTS = stockfish ninja openssl SQLite fmt cpython
STOCKFISH_ARGS = ARCH=armv8
OPENSSL_ARGS = linux-aarch64
CPYTHON_ARGS = --host=aarch64-unknown-linux-gnu --target=aarch64-unknown-linux-gnu
```

What each extra test actually clones and builds is defined once in the
[Makefile](Makefile) ("Extra tests" section) so it stays identical across
every image. You can run any of them locally, the same way CI does:

```bash
make linux-arm64.test-extra          # everything EXTRA_TESTS lists
make linux-arm64.test-stockfish      # one test directly, regardless of EXTRA_TESTS
```

Leave `EXTRA_TESTS` unset for images where a given upstream project doesn't
build (e.g. OpenSSL on some RISC-V targets).
