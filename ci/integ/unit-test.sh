#!/bin/bash
set -euo pipefail

OS=$1
EXTRA_CMAKE_ARGS=${2:-}

if [ "$OS" = "arch" ]; then
  export CC=/usr/bin/clang CXX=/usr/bin/clang++
fi

mkdir -p build && cd build
cmake .. -GNinja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_TESTS=ON \
  $EXTRA_CMAKE_ARGS
ninja
ctest --output-on-failure
