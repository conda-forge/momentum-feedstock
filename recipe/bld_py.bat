@echo on

rem ----------------------------------------------------------------------
rem  Build-time environment
rem ----------------------------------------------------------------------
rem Tell scikit‑build‑core / CMake to use Ninja (avoid Visual Studio)
set "CMAKE_GENERATOR=Ninja"
set "SKBUILD_CMAKE_GENERATOR=Ninja"

rem Make sure nvcc is the CUDA compiler CMake sees
set "CMAKE_CUDA_COMPILER=%CUDA_HOME%\bin\nvcc.exe"

rem Tell CMake where libtorch lives (picked up from the host env)
set "Torch_DIR=%PREFIX%\Library\share\cmake\Torch"

rem CUDA architectures to build – **never quote** the list!
set TORCH_CUDA_ARCH_LIST=5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX

rem Ensure nvcc, cl.exe, etc. are reachable
set "PATH=%CUDA_HOME%\bin;%CONDA_PREFIX%\Library\bin;%PATH%"

rem Extra Momentum options
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_ENABLE_SIMD=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_PYBIND11=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_CUDA_COMPILER=%CMAKE_CUDA_COMPILER%"

if EXIST build (
    cmake --build build --target clean
    if %ERRORLEVEL% neq 0 exit 1
)

rem ----------------------------------------------------------------------
rem  Build & install the wheel with the modern, supported interface
rem ----------------------------------------------------------------------
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation ^
    --config-settings=cmake.build-type=Release ^
    --config-settings=cmake.generator=Ninja ^
    --config-settings=cmake.define.CMAKE_CUDA_COMPILER=%CMAKE_CUDA_COMPILER%

if errorlevel 1 exit 1
