#!/bin/bash

set -euxo pipefail

# Set extra cmake arguments that are not set in https://github.com/facebookincubator/momentum/blob/main/pyproject.toml
export CMAKE_ARGS=" \
  -DMOMENTUM_ENABLE_SIMD=OFF \
"

# Install the current package with verbose output
python -m pip install . -vv
