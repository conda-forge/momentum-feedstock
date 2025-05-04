@echo on

echo CUDA_HOME is set to: %CUDA_HOME%

echo PATH is set to: %PATH%

echo CMAKE_ARGS before is set to: %CMAKE_ARGS%

@REM set "CMAKE_ARGS=%CMAKE_ARGS:\=\\%"

@REM set "CMAKE_ARGS=%CMAKE_ARGS:;= %"

echo CMAKE_ARGS after is set to: %CMAKE_ARGS%

set CONDA_BUILD_SHORT_BUILD_PREFIX=1

set TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"

nvcc --version

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1


if EXIST build (
    cmake --build build --target clean
    if %ERRORLEVEL% neq 0 exit 1
)

@REM %PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
%PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
if errorlevel 1 exit 1

