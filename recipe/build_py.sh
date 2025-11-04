#!/bin/bash

set -exo pipefail

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

export CMAKE_ARGS="$CMAKE_ARGS \
    -DMOMENTUM_BUILD_RENDERER=ON \
    -DMOMENTUM_BUILD_TESTING=OFF \
    -DMOMENTUM_ENABLE_SIMD=OFF \
    -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF \
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON"

if [[ "${target_platform}" != "${build_platform}" ]]; then
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_USE_SYSTEM_GOOGLETEST=OFF"
else
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON"
fi

$PYTHON -m pip install . -vv --no-deps --no-build-isolation

# Run Python unit tests
# Change to a different directory to ensure we import the installed package
cd "${SRC_DIR}/.."
export MOMENTUM_MODELS_PATH="${SRC_DIR}/momentum/"
$PYTHON -m pytest --pyargs pymomentum.test -v
