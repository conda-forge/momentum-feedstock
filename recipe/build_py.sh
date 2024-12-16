#!/bin/bash

set -exo pipefail

# Workaround for fx/gltf.h:70:13: error: narrowing conversion of '-1' from 'int' to 'char' [-Wnarrowing]
if [[ "${target_platform}" == *aarch64 || "${target_platform}" == *ppc64le ]]; then
  CXXFLAGS="${CXXFLAGS} -Wno-narrowing"

  CFLAGS=${CFLAGS/-march=nocona/}
  CFLAGS=${CFLAGS/-mtune=haswell/}

  CXXFLAGS=${CXXFLAGS/-march=nocona/}
  CXXFLAGS=${CXXFLAGS/-mtune=haswell/}
  
  DEBUG_CFLAGS=${DEBUG_CFLAGS/-march=nocona/}
  DEBUG_CFLAGS=${DEBUG_CFLAGS/-mtune=haswell/}

  DEBUG_CXXFLAGS=${DEBUG_CXXFLAGS/-march=nocona/}
  DEBUG_CXXFLAGS=${DEBUG_CXXFLAGS/-mtune=haswell/}
fi

python -m pip install --no-deps --ignore-installed . -vv --prefix=$PREFIX
