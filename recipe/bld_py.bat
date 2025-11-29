@echo on

:: Note: The vs2022_win-64 conda package activation already calls vcvarsall.bat
:: so we don't need to call it again. Calling it twice causes PATH overflow.

:: Get the full path to cl.exe for CMake with Ninja generator
:: Ninja requires the full path, not just the executable name
for /f "usebackq tokens=*" %%a in (`where cl.exe`) do (
    set "CL_PATH=%%a"
    goto :found_cl
)
echo ERROR: cl.exe not found in PATH. The vs2022_win-64 activation may have failed.
exit /b 1
:found_cl
echo Found cl.exe at: %CL_PATH%

:: Get Python prefix to help FindPython locate the library
for /f "usebackq tokens=*" %%a in (`%PYTHON% -c "import sys; print(sys.prefix)"`) do set PYTHON_PREFIX=%%a
:: Convert backslashes to forward slashes for CMake
set PYTHON_PREFIX=%PYTHON_PREFIX:\=/%

:: Get Python version
for /f "usebackq tokens=*" %%a in (`%PYTHON% -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"`) do set PYTHON_VER=%%a

:: Get Python paths
for /f "usebackq tokens=*" %%a in (`%PYTHON% -c "import sys; from pathlib import Path; print(Path(sys.prefix) / 'libs' / f'python{sys.version_info.major}{sys.version_info.minor}.lib')"` ) do set PYTHON_LIB=%%a
set PYTHON_LIB=%PYTHON_LIB:\=/%

for /f "usebackq tokens=*" %%a in (`%PYTHON% -c "import sys; from pathlib import Path; print(Path(sys.prefix) / 'include')"` ) do set PYTHON_INCLUDE=%%a
set PYTHON_INCLUDE=%PYTHON_INCLUDE:\=/%

echo PYTHON_PREFIX: %PYTHON_PREFIX%
echo PYTHON_VER: %PYTHON_VER%
echo PYTHON_LIB: %PYTHON_LIB%
echo PYTHON_INCLUDE: %PYTHON_INCLUDE%

:: Force Ninja generator to avoid VS CUDA integration issues
set CMAKE_GENERATOR=Ninja

:: Convert CL_PATH backslashes to forward slashes for CMake
set CL_PATH_CMAKE=%CL_PATH:\=/%
echo CL_PATH_CMAKE: %CL_PATH_CMAKE%

:: Override the CC and CXX environment variables with the full path
:: CMake with Ninja uses these environment variables to find the compiler
set CC=%CL_PATH%
set CXX=%CL_PATH%
echo CC: %CC%
echo CXX: %CXX%

:: Use SKBUILD_CMAKE_ARGS to pass options to scikit-build-core
:: Pass the full path to cl.exe since Ninja requires it
:: Note: Arguments must be semicolon-separated for scikit-build-core
set SKBUILD_CMAKE_ARGS=-DCMAKE_C_COMPILER="%CL_PATH_CMAKE%";-DCMAKE_CXX_COMPILER="%CL_PATH_CMAKE%";-DMOMENTUM_BUILD_IO_USD=OFF;-DMOMENTUM_BUILD_RENDERER=OFF;-DMOMENTUM_BUILD_TESTING=OFF;-DMOMENTUM_ENABLE_SIMD=OFF;-DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON;-DMOMENTUM_USE_SYSTEM_PYBIND11=ON;-DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON;-DCMAKE_POLICY_DEFAULT_CMP0148=NEW;-DPYBIND11_PYTHON_VERSION="%PYTHON_VER%";-DPython3_ROOT_DIR="%PYTHON_PREFIX%";-DPython3_EXECUTABLE="%PYTHON%";-DPython3_LIBRARY="%PYTHON_LIB%";-DPython3_INCLUDE_DIR="%PYTHON_INCLUDE%";-DPython3_FIND_STRATEGY=LOCATION;-DPython3_FIND_REGISTRY=NEVER

echo SKBUILD_CMAKE_ARGS: %SKBUILD_CMAKE_ARGS%

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation
