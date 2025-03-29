@echo on

echo CUDA_HOME is set to: %CUDA_HOME%

echo PATH is set to: %PATH%

echo CMAKE_ARGS before is set to: %CMAKE_ARGS%

set "CMAKE_ARGS=%CMAKE_ARGS:\=\\%"

echo CMAKE_ARGS after is set to: %CMAKE_ARGS%

@REM if not "%cuda_compiler_version%" == "None" (
@REM     set USE_CUDA=1
@REM     set USE_STATIC_CUDNN=0
@REM     @REM NCCL is not available on windows
@REM     set USE_NCCL=0
@REM     set USE_STATIC_NCCL=0

@REM     @REM set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%desired_cuda%
@REM     @REM set CUDA_BIN_PATH=%CUDA_PATH%\bin

@REM     set "TORCH_CUDA_ARCH_LIST=5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"
@REM     set "TORCH_NVCC_FLAGS=-Xfatbin -compress-all"

@REM     set MAGMA_HOME=%LIBRARY_PREFIX%
@REM     set "PATH=%CUDA_BIN_PATH%;%PATH%"
@REM     set CUDNN_INCLUDE_DIR=%LIBRARY_PREFIX%\include
@REM     set "CUDA_VERSION=%cuda_compiler_version%"
@REM ) else (
@REM     set USE_CUDA=0
@REM     @REM MKLDNN is an Apache-2.0 licensed library for DNNs and is used
@REM     @REM for CPU builds. Not to be confused with MKL.
@REM     set "USE_MKLDNN=1"

@REM     @REM On windows, env vars are case-insensitive and setup.py
@REM     @REM passes all env vars starting with CUDA_*, CMAKE_* to
@REM     @REM to cmake
@REM     set "cuda_compiler_version="
@REM     set "cuda_compiler="
@REM     set "CUDA_VERSION="
@REM )

@REM set DISTUTILS_USE_SDK=1

@REM set CMAKE_INCLUDE_PATH=%LIBRARY_PREFIX%\include
@REM set LIB=%LIBRARY_PREFIX%\lib;%LIB%

@REM @REM CMake configuration
@REM set CMAKE_GENERATOR=Ninja
@REM set "CMAKE_GENERATOR_TOOLSET="
@REM set "CMAKE_GENERATOR_PLATFORM="
@REM set "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%"
@REM set "CMAKE_INCLUDE_PATH=%LIBRARY_INC%"
@REM set "CMAKE_LIBRARY_PATH=%LIBRARY_LIB%"
@REM set "CMAKE_BUILD_TYPE=Release"
@REM @REM This is so that CMake finds the environment's Python, not another one
@REM set Python_EXECUTABLE=%PYTHON%
@REM set Python3_EXECUTABLE=%PYTHON%

@REM set "INSTALL_TEST=0"
@REM set "BUILD_TEST=0"

@REM set "libuv_ROOT=%LIBRARY_PREFIX%"

@REM @REM uncomment to debug cmake build
@REM @REM set "CMAKE_VERBOSE_MAKEFILE=1"

@REM @REM The activation script for cuda-nvcc doesnt add the CUDA_CFLAGS on windows.
@REM @REM Therefore we do this manually here. See:
@REM @REM https://github.com/conda-forge/cuda-nvcc-feedstock/issues/47
@REM echo "CUDA_CFLAGS=%CUDA_CFLAGS%"
@REM set "CUDA_CFLAGS=-I%PREFIX%/Library/include -I%BUILD_PREFIX%/Library/include"
@REM set "CFLAGS=%CFLAGS% %CUDA_CFLAGS%"
@REM set "CPPFLAGS=%CPPFLAGS% %CUDA_CFLAGS%"
@REM set "CXXFLAGS=%CXXFLAGS% %CUDA_CFLAGS%"
@REM echo "CUDA_CFLAGS=%CUDA_CFLAGS%"
@REM echo "CXXFLAGS=%CXXFLAGS%"

set CMAKE_ARGS="%CMAKE_ARGS%" ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

@REM %PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
%PYTHON% -m pip install --no-build-isolation --no-deps --ignore-installed . -vv
if errorlevel 1 exit 1
