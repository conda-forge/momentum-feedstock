#!/bin/bash

set -exo pipefail

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

# Install the current package with verbose output
python -m pip install . -vv \
    --global-option=build_ext \
    --global-option=--cmake-args='
        -DMOMENTUM_BUILD_IO_FBX=OFF
        -DMOMENTUM_BUILD_EXAMPLES=OFF
        -DMOMENTUM_BUILD_TESTING=ON
        -DMOMENTUM_ENABLE_SIMD=OFF
        -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON
        -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF
        -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
    '

# Copy all .so files to the target directory except those containing 'test' in the filename
mkdir -p "$SP_DIR/pymomentum"
find pymomentum -name "*.so" ! -name "*test*" -exec cp {} "$SP_DIR/pymomentum" \;
ls "$SP_DIR/pymomentum"
