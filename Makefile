vc ?= valk
# The directory with libraylib, when raylib is not installed system-wide
RAYLIB_LIB ?=
LINK := $(if $(RAYLIB_LIB),-L $(RAYLIB_LIB),)
RUN := $(if $(RAYLIB_LIB),LD_LIBRARY_PATH=$(RAYLIB_LIB) DYLD_LIBRARY_PATH=$(RAYLIB_LIB),)

valkcraft:
	$(vc) build . --release -o ./valkcraft $(LINK)
run: valkcraft
	$(RUN) ./valkcraft
deps:
	vman install
test:
	@mkdir -p debug
	$(vc) build . --test -o ./debug/tests $(LINK)
	$(RUN) ./debug/tests
lint:
	$(vc) build . --lint

.PHONY: valkcraft run deps test lint
