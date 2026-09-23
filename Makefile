# Settings of this checkout only, e.g. `vc := ~/src/valk/valk` for a compiler of your own
-include local.mk
vc ?= valk
VALK_MIN := 0.7.7
RAYLIB_VERSION := 6.0

# The directory with libraylib. Left empty, the system's raylib is used, or the one
# `make deps` downloads into vendor/raylib when the system has none.
RAYLIB_LIB ?= $(if $(wildcard vendor/raylib/lib),vendor/raylib/lib,)

OS := $(shell uname -s)
ARCH := $(shell uname -m)
ifeq ($(OS),Darwin)
RAYLIB_PACKAGE := macos
HAS_SYSTEM_RAYLIB := $(wildcard /opt/homebrew/lib/libraylib.dylib /usr/local/lib/libraylib.dylib)
RUN := $(if $(RAYLIB_LIB),DYLD_LIBRARY_PATH=$(RAYLIB_LIB),)
LINK := $(if $(RAYLIB_LIB),-L $(RAYLIB_LIB),)
else
RAYLIB_PACKAGE := $(if $(filter aarch64 arm64,$(ARCH)),linux_arm64,linux_amd64)
HAS_SYSTEM_RAYLIB := $(shell ldconfig -p 2>/dev/null | grep -q libraylib && echo yes)
RUN :=
# The program finds the library where it was linked from, without LD_LIBRARY_PATH
LINK := $(if $(RAYLIB_LIB),-L $(RAYLIB_LIB) --link-arg -rpath=$(abspath $(RAYLIB_LIB)),)
endif

valkcraft: check-valk
	$(vc) build . --release -o ./valkcraft $(LINK)
run: valkcraft
	$(RUN) ./valkcraft
deps:
	vman install
	@if [ -z "$(RAYLIB_LIB)" ] && [ -z "$(HAS_SYSTEM_RAYLIB)" ]; then $(MAKE) --no-print-directory raylib; fi
# raylib's own build of the library, from its release page
raylib:
	@echo "raylib is not installed, downloading raylib $(RAYLIB_VERSION) into vendor/raylib"
	@mkdir -p vendor
	curl -fsSL -o vendor/raylib.tar.gz https://github.com/raysan5/raylib/releases/download/$(RAYLIB_VERSION)/raylib-$(RAYLIB_VERSION)_$(RAYLIB_PACKAGE).tar.gz
	rm -rf vendor/raylib vendor/raylib-$(RAYLIB_VERSION)_$(RAYLIB_PACKAGE)
	tar -xzf vendor/raylib.tar.gz -C vendor
	mv vendor/raylib-$(RAYLIB_VERSION)_$(RAYLIB_PACKAGE) vendor/raylib
	rm vendor/raylib.tar.gz
test: check-valk
	@mkdir -p debug
	$(vc) build . --test -o ./debug/tests $(LINK)
	$(RUN) ./debug/tests
lint:
	$(vc) build . --lint
# Older compilers build the game, but pass raylib's structs the wrong way
check-valk:
	@v=$$($(vc) --version 2>&1 | grep -o 'v[0-9][0-9.]*' | head -1 | tr -d v); \
	if [ "$$(printf '%s\n' $(VALK_MIN) $$v | sort -V | head -1)" != "$(VALK_MIN)" ]; then \
		echo "Valkcraft needs valk $(VALK_MIN) or newer, and '$(vc)' is $$v"; exit 1; \
	fi

.PHONY: valkcraft run deps raylib test lint check-valk
