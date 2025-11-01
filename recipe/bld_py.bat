@echo on
setlocal EnableExtensions EnableDelayedExpansion

where nvcc >nul 2>&1 && nvcc --version

rem ----------------------------------------------------------------------
rem  Unpack and enter the source directory
rem ----------------------------------------------------------------------
cd /d %SRC_DIR%
rem Always use Ninja for the Python build
set "CMAKE_GENERATOR=Ninja"
set "CMAKE_BUILD_PARALLEL_LEVEL=%CPU_COUNT%"

rem Convert paths to forward slashes for CMake compatibility
set "LIBRARY_PREFIX_CMAKE=%LIBRARY_PREFIX:\=/%"
set "PREFIX_CMAKE=%PREFIX:\=/%"

rem Fix CMAKE_ARGS paths: convert all backslashes to forward slashes
rem This is needed because conda-build sets CMAKE_ARGS with backslash paths
rem which get stripped when passed through environment variables
set "CMAKE_ARGS=%CMAKE_ARGS:\=/%"

rem Make CMake find previously installed deps from the C++ step
set "CMAKE_PREFIX_PATH=%LIBRARY_PREFIX_CMAKE%"

rem Optional: libtorch hint only if it exists
if exist "%PREFIX%\Library\share\cmake\Torch" set "Torch_DIR=%PREFIX_CMAKE%/Library/share/cmake/Torch"

rem CUDA: only set when the cuda variant is enabled
if /I not "%cuda_compiler_version%"=="None" (
  rem Find nvcc in PATH and derive CUDA_HOME
  where nvcc.exe >nul 2>&1
  if errorlevel 1 (
    echo ERROR: CUDA build requested but nvcc.exe not found in PATH
    exit /b 1
  )

  rem Get the full path to nvcc
  for /f "tokens=*" %%i in ('where nvcc.exe') do set "NVCC_PATH=%%i"

  rem Derive CUDA_HOME: nvcc path is typically CUDA_HOME\bin\nvcc.exe
  rem Extract drive and path, then go up one directory
  for %%i in ("!NVCC_PATH!") do set "CUDA_BIN_DIR=%%~dpi"
  rem Remove trailing backslash from bin directory
  set "CUDA_BIN_DIR=!CUDA_BIN_DIR:~0,-1!"
  rem Get parent directory
  for %%i in ("!CUDA_BIN_DIR!") do set "CUDA_HOME=%%~dpi"
  rem Remove trailing backslash from CUDA_HOME
  set "CUDA_HOME=!CUDA_HOME:~0,-1!"

  rem Convert backslashes to forward slashes for CMake compatibility
  set "CUDACXX=!NVCC_PATH:\=/!"
  set "CUDA_HOME_CMAKE=!CUDA_HOME:\=/!"

  echo Using CUDA from: !CUDA_HOME!
  echo CUDACXX set to: !CUDACXX!
)

rem Extra Momentum options
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_ENABLE_SIMD=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_PYBIND11=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DPython_FIND_STRATEGY=LOCATION"
set "CMAKE_ARGS=%CMAKE_ARGS% -DPython_ROOT_DIR=%PREFIX_CMAKE%"
rem Set CMake policy CMP0148 to enable python_add_library() command
rem Reference: https://github.com/pybind/pybind11/issues/5472
set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_POLICY_DEFAULT_CMP0148=NEW"
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
