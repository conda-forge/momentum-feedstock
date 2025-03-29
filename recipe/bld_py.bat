@echo on

echo CUDA_HOME is set to: %CUDA_HOME%

echo PATH is set to: %PATH%

echo CMAKE_ARGS before is set to: %CMAKE_ARGS%

set "CMAKE_ARGS=%CMAKE_ARGS:\=\\%"

echo CMAKE_ARGS after is set to: %CMAKE_ARGS%

if not "%cuda_compiler_version%" == "None" (
    set USE_CUDA=1
    set USE_STATIC_CUDNN=0
    @REM NCCL is not available on windows
    set USE_NCCL=0
    set USE_STATIC_NCCL=0

    @REM set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%desired_cuda%
    @REM set CUDA_BIN_PATH=%CUDA_PATH%\bin

    set "TORCH_CUDA_ARCH_LIST=5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"
    set "TORCH_NVCC_FLAGS=-Xfatbin -compress-all"

    set MAGMA_HOME=%LIBRARY_PREFIX%
    set "PATH=%CUDA_BIN_PATH%;%PATH%"
    set CUDNN_INCLUDE_DIR=%LIBRARY_PREFIX%\include
    set "CUDA_VERSION=%cuda_compiler_version%"
) else (
    set USE_CUDA=0
    @REM MKLDNN is an Apache-2.0 licensed library for DNNs and is used
    @REM for CPU builds. Not to be confused with MKL.
    set "USE_MKLDNN=1"

    @REM On windows, env vars are case-insensitive and setup.py
    @REM passes all env vars starting with CUDA_*, CMAKE_* to
    @REM to cmake
    set "cuda_compiler_version="
    set "cuda_compiler="
    set "CUDA_VERSION="
)

set DISTUTILS_USE_SDK=1

set CMAKE_INCLUDE_PATH=%LIBRARY_PREFIX%\include
set LIB=%LIBRARY_PREFIX%\lib;%LIB%

@REM CMake configuration
set CMAKE_GENERATOR=Ninja
set "CMAKE_GENERATOR_TOOLSET="
set "CMAKE_GENERATOR_PLATFORM="
set "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%"
set "CMAKE_INCLUDE_PATH=%LIBRARY_INC%"
set "CMAKE_LIBRARY_PATH=%LIBRARY_LIB%"
set "CMAKE_BUILD_TYPE=Release"
@REM This is so that CMake finds the environment's Python, not another one
set Python_EXECUTABLE=%PYTHON%
set Python3_EXECUTABLE=%PYTHON%

set "INSTALL_TEST=0"
set "BUILD_TEST=0"

set "libuv_ROOT=%LIBRARY_PREFIX%"

@REM uncomment to debug cmake build
@REM set "CMAKE_VERBOSE_MAKEFILE=1"

@REM The activation script for cuda-nvcc doesnt add the CUDA_CFLAGS on windows.
@REM Therefore we do this manually here. See:
@REM https://github.com/conda-forge/cuda-nvcc-feedstock/issues/47
echo "CUDA_CFLAGS=%CUDA_CFLAGS%"
set "CUDA_CFLAGS=-I%PREFIX%/Library/include -I%BUILD_PREFIX%/Library/include"
set "CFLAGS=%CFLAGS% %CUDA_CFLAGS%"
set "CPPFLAGS=%CPPFLAGS% %CUDA_CFLAGS%"
set "CXXFLAGS=%CXXFLAGS% %CUDA_CFLAGS%"
echo "CUDA_CFLAGS=%CUDA_CFLAGS%"
echo "CXXFLAGS=%CXXFLAGS%"

set CMAKE_ARGS="%CMAKE_ARGS%" ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

@REM %PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
%PYTHON% -m pip install --no-build-isolation --no-deps --ignore-installed . -vv
if errorlevel 1 exit 1
