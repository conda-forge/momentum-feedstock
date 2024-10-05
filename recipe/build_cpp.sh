#!/bin/bash

set -exo pipefail

# Display environment info
echo CONDA_BUILD_CROSS_COMPILATION: $CONDA_BUILD_CROSS_COMPILATION
echo CROSSCOMPILING_EMULATOR      : $CROSSCOMPILING_EMULATOR
echo build_platform               : $build_platform
echo target_platform              : $target_platform

if [[ "${target_platform}" == osx-* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" || "${target_platform}" == osx-* ]]; then
  momentum_enable_simd=OFF
else
  momentum_enable_simd=ON
fi

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

# Disable tests when cross-compiling
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  build_testing=OFF
else
  build_testing=ON
fi

cmake $SRC_DIR \
  ${CMAKE_ARGS} \
  -G Ninja \
  -B build \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DMOMENTUM_BUILD_EXAMPLES=OFF \
  -DMOMENTUM_BUILD_PYMOMENTUM=OFF \
  -DMOMENTUM_BUILD_TESTING=$build_testing \
  -DMOMENTUM_ENABLE_SIMD=$momentum_enable_simd \
  -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON \
  -DMOMENTUM_USE_SYSTEM_PYBIND11=ON \
  -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON

cmake --build build --parallel

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
  ctest --test-dir build --output-on-failure
fi

cmake --build build --parallel --target install
