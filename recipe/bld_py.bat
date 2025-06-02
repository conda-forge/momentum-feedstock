@echo on

where nvcc >nul 2>&1 && nvcc --version

set TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"

set PATH=%CONDA_PREFIX%\Library\bin;%PATH%

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_BUILD_RENDERER=OFF ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1


if EXIST build (
    cmake --build build --target clean
    if %ERRORLEVEL% neq 0 exit 1
)

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation ^
    --global-option=build_ext ^
    --global-option="-DCMAKE_CUDA_COMPILER=%CONDA_PREFIX%\Library\bin\nvcc.exe"
if errorlevel 1 exit 1
