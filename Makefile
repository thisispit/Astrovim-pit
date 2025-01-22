# Compiler settings
ZIG ?= zig
CFLAGS += -Wall -Werror -fpic -std=gnu99

ifeq ($(OS),Windows_NT)
    TARGET := libfzf.dll
    ifeq (,$(findstring $(MSYSTEM),MSYS UCRT64 CLANG64 CLANGARM64 CLANG32 MINGW64 MINGW32))
        # On Windows, but NOT msys/msys2
        MKD = cmd /C mkdir
        RM = cmd /C rmdir /Q /S
    else
        MKD = mkdir -p
        RM = rm -rf
    endif
else
    MKD = mkdir -p
    RM = rm -rf
    TARGET := libfzf.so
endif

all: build/$(TARGET)

build/$(TARGET): src/fzf.c src/fzf.h
	$(MKD) build
	$(ZIG) build-lib src/fzf.c \
		-O ReleaseFast \
		-dynamic \
		-lc \
		-femit-bin=build/$(TARGET)

build/test: build/$(TARGET) test/test.c
	$(ZIG) build-exe test/test.c \
		-O Debug \
		-I./src \
		-L./build \
		-lfzf \
		-lexaminer \
		-femit-bin=build/test

.PHONY: lint format clangdhappy clean test ntest

lint: luacheck lua

format:
	clang-format --style=file --dry-run -Werror src/fzf.c src/fzf.h test/test.c

test: build/test
	@LD_LIBRARY_PATH=${PWD}/build:${PWD}/examiner/build:${LD_LIBRARY_PATH} ./build/test

ntest:
	nvim --headless --noplugin -u test/minrc.vim -c "PlenaryBustedDirectory test/ { minimal_init = './test/minrc.vim' }"

clangdhappy:
	compiledb make

clean:
	$(RM) build
