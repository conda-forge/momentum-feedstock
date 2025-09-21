@echo on
setlocal EnableExtensions

rem ----------------------------------------------------------------------
rem  Build-time environment
rem ----------------------------------------------------------------------
rem Always use Ninja for the Python build
set "CMAKE_GENERATOR=Ninja"
set "CMAKE_BUILD_PARALLEL_LEVEL=%CPU_COUNT%"

rem Make CMake find previously installed deps from the C++ step
set "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX%"

rem Optional: libtorch hint only if it exists
if exist "%PREFIX%\Library\share\cmake\Torch" set "Torch_DIR=%PREFIX%\Library\share\cmake\Torch"

rem CUDA: only set when the cuda variant is enabled AND nvcc exists
if /I not "%cuda_compiler_version%"=="None" (
  if exist "%CUDA_HOME%\bin\nvcc.exe" (
    set "CUDACXX=%CUDA_HOME%\bin\nvcc.exe"
  ) else (
    echo Requested CUDA build but nvcc not found at %%CUDA_HOME%%\bin\nvcc.exe
    exit /b 1
  )
)

rem Extra Momentum options
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_ENABLE_SIMD=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_PYBIND11=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON"
if defined CUDACXX set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_CUDA_COMPILER=%CUDACXX%"

if EXIST build (
    cmake --build build --target clean
    if %ERRORLEVEL% neq 0 exit 1
)

rem ----------------------------------------------------------------------
rem  Build & install the wheel (use only supported config-settings)
rem ----------------------------------------------------------------------
set "PIP_CSET=-Ccmake.build-type=Release -Cbuild-dir=build/{wheel_tag}"
if defined CUDACXX set "PIP_CSET=%PIP_CSET% -Ccmake.define.CMAKE_CUDA_COMPILER=%CUDACXX%"

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation %PIP_CSET%
if errorlevel 1 exit 1
