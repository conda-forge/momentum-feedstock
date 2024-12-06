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
fi

# Install the current package with verbose output
python -m pip install . -vv \
    --global-option=build_ext \
    --global-option=--cmake-args='
        -DMOMENTUM_BUILD_IO_FBX=OFF
        -DMOMENTUM_BUILD_EXAMPLES=OFF
        -DMOMENTUM_BUILD_TESTING=ON
        -DMOMENTUM_ENABLE_SIMD=OFF
        -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON
        -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF
        -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
    '

# Copy all .so files to the target directory except those containing 'test' in the filename
mkdir -p "$SP_DIR/pymomentum"
find pymomentum -name "*.so" ! -name "*test*" -exec cp {} "$SP_DIR/pymomentum" \;
ls "$SP_DIR/pymomentum"
