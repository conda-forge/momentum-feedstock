#!/bin/bash

set -exo pipefail

# Workaround for PyTorch 2.9 CMake config issue on Unix:
# The pytorch package's TorchConfig.cmake references include directories like
# "torch/include/torch/csrc/api/include" that don't exist. The libtorch package
# provides proper C++ headers at $PREFIX/include/torch/.
# Solution: Symlink libtorch headers to the locations pytorch expects.
TORCH_SITE_PACKAGES="${PREFIX}/lib/python${PY_VER}/site-packages/torch"
LIBTORCH_INCLUDE="${PREFIX}/include"
if [[ -d "${TORCH_SITE_PACKAGES}/include" ]] && [[ -d "${LIBTORCH_INCLUDE}/torch" ]]; then
  echo "Linking libtorch headers to pytorch site-packages..."

  # Backup existing include dir and replace with libtorch headers
  if [[ -d "${TORCH_SITE_PACKAGES}/include/torch" ]]; then
    rm -rf "${TORCH_SITE_PACKAGES}/include/torch"
  fi
  ln -sf "${LIBTORCH_INCLUDE}/torch" "${TORCH_SITE_PACKAGES}/include/torch"

  # Create the api/include subdirectory that TorchConfig.cmake references
  mkdir -p "${TORCH_SITE_PACKAGES}/include/torch/csrc/api/include"

  echo "Libtorch headers linked successfully"
  ls -la "${TORCH_SITE_PACKAGES}/include/"
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
