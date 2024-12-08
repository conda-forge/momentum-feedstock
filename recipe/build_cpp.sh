#!/bin/bash

set -exo pipefail

if [[ "${target_platform}" == osx-* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" || "${target_platform}" == osx-* ]]; then
  MOMENTUM_ENABLE_SIMD=OFF
else
  MOMENTUM_ENABLE_SIMD=ON
fi

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"
fi

# Disable use of system-installed GTest libraries when cross-compiling
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
  MOMENTUM_USE_SYSTEM_GOOGLETEST=ON
else
  MOMENTUM_USE_SYSTEM_GOOGLETEST=OFF
fi

cmake $SRC_DIR \
  ${CMAKE_ARGS} \
  -G Ninja \
  -B build \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DMOMENTUM_BUILD_EXAMPLES=OFF \
  -DMOMENTUM_BUILD_PYMOMENTUM=OFF \
  -DMOMENTUM_BUILD_TESTING=ON \
  -DMOMENTUM_ENABLE_SIMD=$MOMENTUM_ENABLE_SIMD \
  -DMOMENTUM_USE_SYSTEM_GOOGLETEST=$MOMENTUM_USE_SYSTEM_GOOGLETEST \
  -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF \
  -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON

cmake --build build --parallel

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
  ctest --test-dir build --output-on-failure
fi

cmake --build build --parallel --target install
