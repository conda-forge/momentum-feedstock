#!/bin/bash

set -exo pipefail

# On Unix, use libtorch package for C++ headers instead of pytorch package.
# The pytorch package's TorchConfig.cmake references non-existent include
# directories, while libtorch provides proper C++ headers and CMake config.
# See: https://github.com/conda-forge/pytorch-cpu-feedstock/issues/474
if [[ -f "${PREFIX}/lib/cmake/Torch/TorchConfig.cmake" ]]; then
  export Torch_DIR="${PREFIX}/lib/cmake/Torch"
  echo "Using libtorch CMake config: ${Torch_DIR}"
fi

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

# Disable IO_USD on macOS or when openusd is not available
# (openusd is skipped for PyTorch 2.7/2.8 due to TBB conflict)
if [[ "${target_platform}" == osx-* ]]; then
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_BUILD_IO_USD=OFF"
elif [[ ! -d "${PREFIX}/include/pxr" ]]; then
  # openusd is not available (check for pxr headers)
  export CMAKE_ARGS="$CMAKE_ARGS -DMOMENTUM_BUILD_IO_USD=OFF"
fi

$PYTHON -m pip install . -vv --no-deps --no-build-isolation
