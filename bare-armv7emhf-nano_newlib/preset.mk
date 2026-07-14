BASE_IMAGE_REGISTRY ?= docker.io
BASE_IMAGE_PATH ?= dockcross
BASE_IMAGE_NAME = base
BASE_IMAGE_TAG  = latest

OUTPUT_IMAGE_REGISTRY ?= docker.io
OUTPUT_IMAGE_PATH ?= dockcross
OUTPUT_IMAGE_NAME = bare-armv7emhf-nano_newlib

TEST_IMAGE_ARGS = --linker-flags="--specs=nosys.specs"

# Extra tests (see CONTRIBUTING.md / Makefile "Extra tests" section)
EXTRA_TESTS = mbedtls libopencm3
LIBOPENCM3_ARGS = PREFIX=/usr/xcc/arm-none-eabi/bin/arm-none-eabi- TARGETS='stm32/f1 stm32/f2 stm32/f3 stm32/f4 stm32/f7 stm32/l1 stm32/l4 stm32/g4 stm32/h7 gd32/f1x0 lpc13xx lpc17xx lpc43xx/m4 lm3s lm4f msp432/e4 efm32/tg efm32/g efm32/lg efm32/gg efm32/wg efm32/ezr32wg nrf/51 nrf/52 sam/3a sam/3n sam/3s sam/3u sam/3x sam/4l vf6xx pac55xx'
