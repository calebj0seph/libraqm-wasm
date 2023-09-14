# libraqm-wasm

A script for building libraqm to WebAssembly. Avoids GPL dependencies by using
[SheenBidi](https://github.com/Tehreer/SheenBidi) instead of
[FriBidi](https://www.fribidi.org/).

Requires [Emscripten](https://emscripten.org/),
[Binaryen](https://github.com/WebAssembly/binaryen) and
[Brotli](https://github.com/google/brotli) to be installed. If using Homebrew,
you can install these with:
```
brew install emscripten binaryen brotli
```
