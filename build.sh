#!/usr/bin/env bash
set -e
shopt -s nullglob

# Dependencies
HARFBUZZ_GIT_URL="https://github.com/harfbuzz/harfbuzz.git"
HARFBUZZ_GIT_TAG="8.2.2"
HARFBUZZ_GIT_DIR="harfbuzz"
SHEENBIDI_GIT_URL="https://github.com/Tehreer/SheenBidi.git"
SHEENBIDI_GIT_TAG="v2.6"
SHEENBIDI_GIT_DIR="sheenbidi"
RAQM_GIT_URL="https://github.com/HOST-Oman/libraqm.git"
RAQM_GIT_TAG="v0.10.1"
RAQM_GIT_DIR="raqm"

# Cleanup
function clean_build_dirs {
  rm -f *.o *.wasm
  rm -rf "$HARFBUZZ_GIT_DIR"
  rm -rf "$SHEENBIDI_GIT_DIR"
  rm -rf "$RAQM_GIT_DIR"
}

echo "Cleaning build directories..."
rm -f *.js *.br
clean_build_dirs

# Clone repositories
echo "Cloning Harfbuzz ($HARFBUZZ_GIT_TAG)..."
git clone --quiet --depth 1 -c "advice.detachedHead=false" --branch "$HARFBUZZ_GIT_TAG" "$HARFBUZZ_GIT_URL" "$HARFBUZZ_GIT_DIR"
echo "Cloning SheenBidi ($SHEENBIDI_GIT_TAG)..."
git clone --quiet --depth 1 -c "advice.detachedHead=false" --branch "$SHEENBIDI_GIT_TAG" "$SHEENBIDI_GIT_URL" "$SHEENBIDI_GIT_DIR"
echo "Cloning Raqm ($RAQM_GIT_TAG)..."
git clone --quiet --depth 1 -c "advice.detachedHead=false" --branch "$RAQM_GIT_TAG" "$RAQM_GIT_URL" "$RAQM_GIT_DIR"

# Patch Raqm to not depend on freetype
echo "Patching Raqm..."
cd "$RAQM_GIT_DIR"
git apply "../raqm-remove-freetype.patch"
cd ..

# Compile
echo "Compiling Harfbuzz..."
em++ \
  -std=c++11 \
  -fno-exceptions \
  -fno-rtti \
  -fno-threadsafe-statics \
  -fvisibility-inlines-hidden \
  -flto \
  -Oz \
  -I. \
  -c \
  -o harfbuzz-wasm.o \
  harfbuzz-wasm.cc

echo "Compiling Raqm..."
emcc \
  -std=c99 \
  -fvisibility-inlines-hidden \
  -flto \
  -Oz \
  -I. \
  -I"$HARFBUZZ_GIT_DIR/src" \
  -I"$SHEENBIDI_GIT_DIR/Headers" \
  -c \
  -o libraqm-wasm.o \
  libraqm-wasm.c

echo "Linking..."
emcc \
  -flto \
  -Oz \
  --no-entry \
  -s INITIAL_MEMORY=128MB \
  -s INCOMING_MODULE_JS_API='["print", "printErr", "onAbort"]' \
  -s EXPORTED_FUNCTIONS=@libraqm-wasm.symbols \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s EXPORT_NAME="Raqm" \
  -s STANDALONE_WASM=1 \
  -o raqm.js \
  harfbuzz-wasm.o \
  libraqm-wasm.o \

# Compress
echo "Compressing WASM binary with Brotli..."
brotli -n -o raqm.wasm.br -Z raqm.wasm
rm raqm.wasm

# Cleanup
clean_build_dirs
