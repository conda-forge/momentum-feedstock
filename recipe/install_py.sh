#!/bin/bash

set -exo pipefail

# Install this output's wheel from the pymomentum-build staging output.
$PYTHON -m pip install "${SRC_DIR}/pymomentum_wheels/${PKG_NAME}"/*.whl -vv --no-deps --no-index
