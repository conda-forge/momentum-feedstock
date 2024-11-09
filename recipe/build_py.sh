#!/bin/bash

set -exo pipefail

# Set CMake options for pymomentum
export MOMENTUM_ENABLE_SIMD=OFF
export MOMENTUM_USE_SYSTEM_PYBIND11=OFF

# Install the current package with verbose output
python -m pip install . -vv

# Copy all .so files to the target directory except those containing 'test' in the filename
mkdir -p "$SP_DIR/pymomentum"
find pymomentum -name "*.so" ! -name "*test*" -exec cp {} "$SP_DIR/pymomentum" \;
ls "$SP_DIR/pymomentum"
