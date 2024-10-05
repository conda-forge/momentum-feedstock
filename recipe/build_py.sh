#!/bin/bash

set -exo pipefail

# Display environment info
echo CONDA_BUILD_CROSS_COMPILATION: $CONDA_BUILD_CROSS_COMPILATION
echo CROSSCOMPILING_EMULATOR      : $CROSSCOMPILING_EMULATOR
echo build_platform               : $build_platform
echo target_platform              : $target_platform

# Set CMake options for pymomentum
export MOMENTUM_BUILD_TESTING=OFF
export MOMENTUM_ENABLE_SIMD=OFF

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

# Install the current package with verbose output
python -m pip install . -vv

# Copy all .so files to the target directory except those containing 'test' in the filename
mkdir -p "$SP_DIR/pymomentum"
find pymomentum -name "*.so" ! -name "*test*" -exec cp {} "$SP_DIR/pymomentum" \;
ls "$SP_DIR/pymomentum"
