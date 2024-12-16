#!/bin/bash

set -exo pipefail

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"

  CFLAGS=${CFLAGS/-march=nocona/}
  DEBUG_CFLAGS=${DEBUG_CFLAGS/-march=nocona/}
fi

python -m pip install --no-deps --ignore-installed . -vv --prefix=$PREFIX
