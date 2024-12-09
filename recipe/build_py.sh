#!/bin/bash

set -euxo pipefail

if [[ ${cuda_compiler_version} != "None" ]]; then
  # PyTorch has multiple different bits of logic finding CUDA, override
  # all of them.
  export CUDAToolkit_BIN_DIR=${BUILD_PREFIX}/bin
  export CUDAToolkit_ROOT_DIR=${PREFIX}
  if [[ "${target_platform}" != "${build_platform}" ]]; then
    export CUDA_TOOLKIT_ROOT=${PREFIX}
  fi
  case ${target_platform} in
    linux-64)
      export CUDAToolkit_TARGET_DIR=${PREFIX}/targets/x86_64-linux
      ;;
    linux-aarch64)
      export CUDAToolkit_TARGET_DIR=${PREFIX}/targets/sbsa-linux
      ;;
    *)
      echo "unknown CUDA arch, edit build.sh"
      exit 1
  esac
  case ${cuda_compiler_version} in
    12.6)
      export TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"
      ;;
    *)
      echo "unsupported cuda version. edit build.sh"
      exit 1
  esac
fi

# Set extra cmake arguments that are not set in https://github.com/facebookincubator/momentum/blob/main/pyproject.toml
export CMAKE_ARGS=" \
  -DMOMENTUM_BUILD_TESTING=OFF \
  -DMOMENTUM_ENABLE_SIMD=OFF \
"

# Install the current package with verbose output
python -m pip install . -vv

# # Step 1: Build the wheel
# pip wheel . -w dist

# # Step 2: Determine the wheel file name
# WHEEL_FILE=$(ls dist/*.whl)

# # Step 3: Unpack the wheel
# DEST_DIR="unpacked_wheel"
# wheel unpack "$WHEEL_FILE" --dest "$DEST_DIR"

# # Step 4: Inspect the contents
# echo "Contents of the unpacked wheel:"
# ls "$DEST_DIR"

# # Assuming the package name is pymomentum and version is 0.1.0
# # Adjust the following line based on the actual package name and version
# PACKAGE_DIR=$(ls "$DEST_DIR" | grep 'pymomentum-0.1.0')
# echo "Contents of the package directory:"
# ls "$DEST_DIR/$PACKAGE_DIR"
# ls "$DEST_DIR/$PACKAGE_DIR/pymomentum"
# ls "$DEST_DIR/$PACKAGE_DIR/pymomentum-0.1.0.dist-info"

ls "$SP_DIR"
ls "$SP_DIR/pymomentum"
