@echo on
setlocal EnableExtensions EnableDelayedExpansion

rem ------------------------------------------------------------------
rem  Unpack and enter the source directory
rem ------------------------------------------------------------------
cd /d %SRC_DIR%

rem ------------------------------------------------------------------
rem  Direct CMake build for pymomentum
rem  Using direct CMake instead of scikit-build-core to have full control
rem  over the build type (Release) and avoid debug/release mismatch issues
rem ------------------------------------------------------------------

rem Create build directory (use build_py to avoid conflict with C++ build directory)
if exist build_py rmdir /s /q build_py
mkdir build_py
cd build_py

rem Configure with CMake - explicitly set Release mode and all necessary options
cmake .. -G Ninja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%;%PREFIX%" ^
    -DPython_EXECUTABLE="%PYTHON%" ^
    -DPython3_EXECUTABLE="%PYTHON%" ^
    -DMOMENTUM_BUILD_PYMOMENTUM=ON ^
    -DMOMENTUM_BUILD_IO_USD=OFF ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=OFF ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON ^
    -DCMAKE_POLICY_DEFAULT_CMP0148=NEW
if errorlevel 1 exit 1

rem Build
cmake --build . --config Release --parallel
if errorlevel 1 exit 1

rem Install
cmake --install . --config Release
if errorlevel 1 exit 1

rem ------------------------------------------------------------------
rem  Copy pymomentum to site-packages
rem  CMake installs to LIBRARY_PREFIX/pymomentum, but conda expects
rem  Python packages in SP_DIR (site-packages)
rem ------------------------------------------------------------------
echo Copying pymomentum to site-packages...
if exist "%LIBRARY_PREFIX%\pymomentum" (
    xcopy /E /I /Y "%LIBRARY_PREFIX%\pymomentum" "%SP_DIR%\pymomentum"
    if errorlevel 1 exit 1
) else (
    echo ERROR: pymomentum not found in %LIBRARY_PREFIX%\pymomentum
    exit 1
)

rem ------------------------------------------------------------------
rem  Add DLL search path setup to pymomentum __init__.py
rem  On Windows, the .pyd files depend on DLLs in Library/bin that
rem  need to be in the DLL search path
rem ------------------------------------------------------------------
echo Adding DLL search path setup to pymomentum __init__.py...
set "INIT_FILE=%SP_DIR%\pymomentum\__init__.py"

rem Create a temporary file with the DLL path setup code
echo import os > "%INIT_FILE%.tmp"
echo import sys >> "%INIT_FILE%.tmp"
echo. >> "%INIT_FILE%.tmp"
echo # Add conda Library/bin to DLL search path on Windows >> "%INIT_FILE%.tmp"
echo if sys.platform == 'win32': >> "%INIT_FILE%.tmp"
echo     _conda_prefix = os.environ.get('CONDA_PREFIX', '') >> "%INIT_FILE%.tmp"
echo     if _conda_prefix: >> "%INIT_FILE%.tmp"
echo         _lib_bin = os.path.join(_conda_prefix, 'Library', 'bin') >> "%INIT_FILE%.tmp"
echo         if os.path.isdir(_lib_bin): >> "%INIT_FILE%.tmp"
echo             os.add_dll_directory(_lib_bin) >> "%INIT_FILE%.tmp"
echo         # Also add the package directory for any local DLLs >> "%INIT_FILE%.tmp"
echo         _pkg_dir = os.path.dirname(__file__) >> "%INIT_FILE%.tmp"
echo         if os.path.isdir(_pkg_dir): >> "%INIT_FILE%.tmp"
echo             os.add_dll_directory(_pkg_dir) >> "%INIT_FILE%.tmp"
echo. >> "%INIT_FILE%.tmp"

rem Append the original __init__.py content if it exists
if exist "%INIT_FILE%" (
    type "%INIT_FILE%" >> "%INIT_FILE%.tmp"
)

rem Replace the original with the new file
move /Y "%INIT_FILE%.tmp" "%INIT_FILE%"
if errorlevel 1 exit 1

echo Build completed successfully!
