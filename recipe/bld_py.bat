@echo on
setlocal EnableExtensions EnableDelayedExpansion

where nvcc >nul 2>&1 && nvcc --version

rem ----------------------------------------------------------------------
rem  Unpack and enter the source directory
rem ----------------------------------------------------------------------
cd /d %SRC_DIR%

rem ----------------------------------------------------------------------
rem  Fix python_add_library issue by injecting CMake policy
rem  Reference: https://github.com/pybind/pybind11/issues/5472
rem ----------------------------------------------------------------------
echo Injecting CMake policy CMP0148 into pymomentum/CMakeLists.txt
powershell -Command "$content = Get-Content 'pymomentum/CMakeLists.txt' -Raw; $policy = \"`n# Set CMake policy to use modern FindPython3 module`n\"; $policy += \"# This enables python_add_library() command required by pybind11 2.13.6`n\"; $policy += \"if(POLICY CMP0148)`n\"; $policy += \"  cmake_policy(SET CMP0148 NEW)`n\"; $policy += \"endif()`n`n\"; $content = $content -replace '(find_package\(Torch REQUIRED\))', \"$policy`$1\"; Set-Content 'pymomentum/CMakeLists.txt' -Value $content"
if errorlevel 1 exit 1

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

rem Find cl.exe compiler and set environment variables for Ninja
rem Ninja generator on Windows requires CC/CXX env vars instead of CMake args
for /f "tokens=*" %%i in ('where cl.exe 2^>nul') do set "CL_PATH=%%i"
if not defined CL_PATH (
  echo ERROR: cl.exe not found in PATH
  exit /b 1
)

rem Convert to 8.3 short path to avoid issues with spaces
for %%i in ("!CL_PATH!") do set "CL_PATH_SHORT=%%~si"
echo Using C++ compiler: !CL_PATH_SHORT!

rem Set compiler environment variables for CMake/Ninja (using short path)
set "CC=!CL_PATH_SHORT!"
set "CXX=!CL_PATH_SHORT!"

rem Prevent scikit-build-core from setting platform/toolset (Ninja doesn't support them)
set "CMAKE_GENERATOR_PLATFORM="
set "CMAKE_GENERATOR_TOOLSET="

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
set SKBUILD_CMAKE_ARGS=^
    -DMOMENTUM_BUILD_IO_USD=OFF ^
    -DMOMENTUM_BUILD_RENDERER=OFF ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON ^
    -DCMAKE_POLICY_DEFAULT_CMP0148=NEW ^
    -DPYBIND11_PYTHON_VERSION="%PYTHON_VER%" ^
    -DPython3_ROOT_DIR="%PYTHON_PREFIX%" ^
    -DPython3_EXECUTABLE="%PYTHON%" ^
    -DPython3_LIBRARY="%PYTHON_LIB%" ^
    -DPython3_INCLUDE_DIR="%PYTHON_INCLUDE%" ^
    -DPython3_FIND_STRATEGY=LOCATION ^
    -DPython3_FIND_REGISTRY=NEVER

echo SKBUILD_CMAKE_ARGS: %SKBUILD_CMAKE_ARGS%

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation
if errorlevel 1 exit 1
