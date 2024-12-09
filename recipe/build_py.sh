#!/bin/bash

set -euxo pipefail

if [[ ${cuda_compiler_version} != "None" ]]; then
  # Set the CUDA arch list from
  # https://github.com/conda-forge/pytorch-cpu-feedstock/blob/main/recipe/build_pytorch.sh
  if [[ ${cuda_compiler_version} == 11.8 ]]; then
    export TORCH_CUDA_ARCH_LIST="3.5;5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9+PTX"
    export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
  elif [[ ${cuda_compiler_version} == 12.0 || ${cuda_compiler_version} == 12.6 ]]; then
    export TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"
    # $CUDA_HOME not set in CUDA 12.0. Using $PREFIX
    export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
    # CUDA_HOME must be set for the build to work in torchaudio
    export CUDA_HOME="${PREFIX}"
  else
    echo "unsupported cuda version. edit build.sh"
    exit 1
  fi

  if [[ "${target_platform}" != "${build_platform}" ]]; then
    export CUDA_TOOLKIT_ROOT=${PREFIX}
  fi
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
