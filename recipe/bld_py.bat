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
rem  Create __init__.py with DLL search path setup as fallback
rem  This adds Library/bin to DLL search path in case some DLLs
rem  couldn't be copied
rem ------------------------------------------------------------------
echo Creating __init__.py with DLL search path setup...
set "INIT_FILE=%PYM_DIR%\__init__.py"
set "INIT_TMP=%PYM_DIR%\__init__.py.tmp"

rem Use Python to create the init file properly
"%PYTHON%" -c "
import os
import sys

init_file = os.environ['INIT_FILE']
init_tmp = os.environ['INIT_TMP']

# DLL search path setup code
dll_setup = '''import os as _os
import sys as _sys

# Add DLL search paths on Windows for pymomentum native extensions
if _sys.platform == 'win32':
    # Add package directory (where we copy DLLs during build)
    _pkg_dir = _os.path.dirname(__file__)
    if _os.path.isdir(_pkg_dir):
        _os.add_dll_directory(_pkg_dir)
    # Add conda Library/bin as fallback
    _conda_prefix = _os.environ.get('CONDA_PREFIX', '')
    if _conda_prefix:
        _lib_bin = _os.path.join(_conda_prefix, 'Library', 'bin')
        if _os.path.isdir(_lib_bin):
            _os.add_dll_directory(_lib_bin)
    del _pkg_dir, _conda_prefix, _lib_bin
del _os, _sys

'''

# Read existing content if any
existing = ''
if os.path.exists(init_file):
    with open(init_file, 'r') as f:
        existing = f.read()

# Write new file with DLL setup prepended
with open(init_tmp, 'w') as f:
    f.write(dll_setup)
    f.write(existing)

print('Successfully created __init__.py with DLL setup')
"
if errorlevel 1 (
    echo WARNING: Failed to create __init__.py with Python, trying batch method...
    goto :batch_init
)

rem Replace original with temp file
move /Y "%INIT_TMP%" "%INIT_FILE%"
if errorlevel 1 exit 1
goto :done_init

:batch_init
rem Fallback: create a simple __init__.py using batch
echo import os; os.add_dll_directory(os.path.dirname(__file__)) if hasattr(os, 'add_dll_directory') else None > "%INIT_FILE%.new"
if exist "%INIT_FILE%" (
    type "%INIT_FILE%" >> "%INIT_FILE%.new"
)
move /Y "%INIT_FILE%.new" "%INIT_FILE%"

:done_init
echo Build completed successfully!
