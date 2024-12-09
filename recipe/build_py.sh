#!/bin/bash

set -euxo pipefail

# Set extra cmake arguments that are not set in https://github.com/facebookincubator/momentum/blob/main/pyproject.toml
export CMAKE_ARGS=" \
  -DMOMENTUM_BUILD_TESTING=OFF \
  -DMOMENTUM_ENABLE_SIMD=OFF \
"

# Install the current package with verbose output
# python -m pip install . -vv

# Step 1: Build the wheel
pip wheel . -w dist

# Step 2: Determine the wheel file name
WHEEL_FILE=$(ls dist/*.whl)

# Step 3: Unpack the wheel
DEST_DIR="unpacked_wheel"
wheel unpack "$WHEEL_FILE" --dest "$DEST_DIR"

# Step 4: Inspect the contents
echo "Contents of the unpacked wheel:"
ls "$DEST_DIR"

# Assuming the package name is pymomentum and version is 0.1.0
# Adjust the following line based on the actual package name and version
PACKAGE_DIR=$(ls "$DEST_DIR" | grep 'pymomentum-0.1.0')
echo "Contents of the package directory:"
ls "$DEST_DIR/$PACKAGE_DIR"
ls "$DEST_DIR/$PACKAGE_DIR/pymomentum"
ls "$DEST_DIR/$PACKAGE_DIR/pymomentum-0.1.0.dist-info"
