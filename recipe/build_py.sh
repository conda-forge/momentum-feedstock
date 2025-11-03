#!/bin/bash

set -exo pipefail

if [[ "${target_platform}" == osx-* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

# Disable renderer for CUDA builds due to pybind11/nvcc template incompatibility
if [[ -n "${cuda_compiler_version}" && "${cuda_compiler_version}" != "None" ]]; then
  MOMENTUM_BUILD_RENDERER=OFF
else
  MOMENTUM_BUILD_RENDERER=ON
fi

export CMAKE_ARGS="$CMAKE_ARGS \
    -DMOMENTUM_BUILD_RENDERER=$MOMENTUM_BUILD_RENDERER \
    -DMOMENTUM_BUILD_TESTING=OFF \
    -DMOMENTUM_ENABLE_SIMD=OFF \
    -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF \
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON"

if [[ "${target_platform}" != "${build_platform}" ]]; then
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_USE_SYSTEM_GOOGLETEST=OFF"
else
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON"
fi

# Disable IO_USD on macOS
if [[ "${target_platform}" == osx-* ]]; then
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_BUILD_IO_USD=OFF"
fi

$PYTHON -m pip install . -vv --no-deps --no-build-isolation

# Run Python unit tests
export MOMENTUM_MODELS_PATH="${SRC_DIR}/momentum/"
pytest pymomentum/test/*.py -v
