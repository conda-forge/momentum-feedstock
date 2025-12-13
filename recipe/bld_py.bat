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
rem  Copy momentum DLLs to pymomentum package directory
rem  On Windows, .pyd files need their dependent DLLs in the same
rem  directory or in a directory that's in the DLL search path.
rem  Copying to the same directory is the most reliable approach.
rem ------------------------------------------------------------------
echo Copying momentum DLLs to pymomentum package directory...
set "PYM_DIR=%SP_DIR%\pymomentum"

rem Copy momentum*.dll files from Library/bin
if exist "%LIBRARY_BIN%\momentum*.dll" (
    echo Found momentum DLLs in %LIBRARY_BIN%
    copy /Y "%LIBRARY_BIN%\momentum*.dll" "%PYM_DIR%\"
    if errorlevel 1 (
        echo WARNING: Failed to copy momentum DLLs, but continuing...
    )
)

rem Also copy any other required DLLs that momentum depends on
rem These are typically installed by the momentum-cpp package
for %%d in (
    OpenFBX.dll
    fmt.dll
    spdlog.dll
    drjit.dll
    drjit-core.dll
    nanothread.dll
) do (
    if exist "%LIBRARY_BIN%\%%d" (
        echo Copying %%d
        copy /Y "%LIBRARY_BIN%\%%d" "%PYM_DIR%\"
    )
)

rem List DLLs in Library/bin for debugging
echo.
echo DLLs in %LIBRARY_BIN%:
dir /b "%LIBRARY_BIN%\*.dll" 2>nul || echo No DLLs found in Library/bin

rem List what's in the pymomentum directory
echo.
echo Files in %PYM_DIR%:
dir /b "%PYM_DIR%\*.dll" "%PYM_DIR%\*.pyd" 2>nul || echo No DLLs or PYD files found

rem ------------------------------------------------------------------
rem  Create __init__.py with DLL search path setup
rem  This ensures DLLs are findable before any module imports
rem ------------------------------------------------------------------
echo Creating __init__.py with DLL search path setup...
set "INIT_FILE=%PYM_DIR%\__init__.py"
set "INIT_BAK=%PYM_DIR%\__init__.py.bak"
set "INIT_TEMP=%PYM_DIR%\__init__.py.tmp"

rem Backup original __init__.py if it exists
if exist "%INIT_FILE%" (
    copy /Y "%INIT_FILE%" "%INIT_BAK%"
)

rem Create new __init__.py with proper DLL setup at the very beginning
rem This MUST execute before any submodule imports
(
echo # Auto-generated DLL loading setup for Windows
echo import sys
echo import os
echo if sys.platform == 'win32' and hasattr^(os, 'add_dll_directory'^):
echo     # Add package directory to DLL search path
echo     _pkg_dir = os.path.dirname^(__file__^)
echo     if _pkg_dir:
echo         try:
echo             os.add_dll_directory^(_pkg_dir^)
echo         except Exception:
echo             pass
echo     # Add conda Library/bin to DLL search path
echo     if 'CONDA_PREFIX' in os.environ:
echo         _lib_bin = os.path.join^(os.environ['CONDA_PREFIX'], 'Library', 'bin'^)
echo         if os.path.isdir^(_lib_bin^):
echo             try:
echo                 os.add_dll_directory^(_lib_bin^)
echo             except Exception:
echo                 pass
echo.
) > "%INIT_TEMP%"

rem Append original content if backup exists
if exist "%INIT_BAK%" (
    type "%INIT_BAK%" >> "%INIT_TEMP%"
    del "%INIT_BAK%"
)

rem Move temp file to final location
move /Y "%INIT_TEMP%" "%INIT_FILE%"

echo __init__.py created successfully
echo.
echo Contents of __init__.py first 20 lines:
type "%INIT_FILE%" | more +0 /E +20

echo Build completed successfully!
