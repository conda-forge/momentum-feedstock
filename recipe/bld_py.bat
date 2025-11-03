@echo on
setlocal EnableExtensions EnableDelayedExpansion

rem ------------------------------------------------------------------
rem  Detect CUDA build
rem  CUDA_COMPILER_VERSION is set by conda-build; "None" means CPU build
rem ------------------------------------------------------------------
set IS_CUDA_BUILD=0
if defined cuda_compiler_version (
    if not "%cuda_compiler_version%"=="None" (
        set IS_CUDA_BUILD=1
        echo Detected CUDA build: cuda_compiler_version=%cuda_compiler_version%
    ) else (
        echo Detected CPU build: cuda_compiler_version=None
    )
) else (
    echo Detected CPU build: cuda_compiler_version not defined
)

rem ------------------------------------------------------------------
rem  CPU build: Use simple pip install (original approach that works)
rem  CUDA build: Use direct CMake for better control over Release mode
rem ------------------------------------------------------------------
cd /d %SRC_DIR%

if %IS_CUDA_BUILD%==0 (
    echo Using pip install for CPU build...
    set CMAKE_ARGS=%CMAKE_ARGS% ^
        -DMOMENTUM_BUILD_IO_USD=OFF ^
        -DMOMENTUM_BUILD_RENDERER=OFF ^
        -DMOMENTUM_BUILD_TESTING=OFF ^
        -DMOMENTUM_ENABLE_SIMD=OFF ^
        -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
        -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
        -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
    %PYTHON% -m pip install . -vv --no-deps --no-build-isolation
    if errorlevel 1 exit 1
    echo CPU build completed successfully!
    goto :EOF
)

rem ------------------------------------------------------------------
rem  CUDA build: Direct CMake build for pymomentum
rem  Using direct CMake instead of scikit-build-core to have full control
rem  over the build type (Release) and avoid debug/release mismatch issues
rem ------------------------------------------------------------------
echo Using direct CMake for CUDA build...

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
    -DMOMENTUM_BUILD_RENDERER=ON ^
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

rem Copy Kokkos DLLs - these are critical for geometry module with CUDA
rem NOTE: NOT copying kokkos DLLs to package dir - they have complex deps (nvcuda.dll etc)
rem       that cause overlinking errors. Let them be found via os.add_dll_directory()
echo NOTE: Kokkos DLLs NOT copied (found via Library/bin to avoid overlinking errors)

rem Also copy any other required DLLs that momentum depends on
rem These are typically installed by the momentum-cpp package
rem NOTE: NOT copying ceres.dll - it has many CUDA/LAPACK deps that cause overlinking
rem       Let it be found via os.add_dll_directory() in Library/bin
echo Copying other dependency DLLs...
for %%d in (
    OpenFBX.dll
    fmt.dll
    spdlog.dll
    drjit.dll
    drjit-core.dll
    nanothread.dll
    dispenso.dll
    gflags.dll
    ezc3d.dll
) do (
    if exist "%LIBRARY_BIN%\%%d" (
        echo Copying %%d
        copy /Y "%LIBRARY_BIN%\%%d" "%PYM_DIR%\"
    )
)

rem ------------------------------------------------------------------
rem  Create __init__.py with DLL search path setup
rem  Use a Python script to generate it to ensure proper indentation
rem ------------------------------------------------------------------
echo Creating __init__.py with DLL search path setup...
set "INIT_FILE=%PYM_DIR%\__init__.py"
set "INIT_BAK=%PYM_DIR%\__init__.py.bak"

rem Backup original __init__.py if it exists
if exist "%INIT_FILE%" (
    copy /Y "%INIT_FILE%" "%INIT_BAK%"
)

rem Use Python to create the __init__.py with proper DLL loading code
python -c "import sys; sys.stdout.write('''# Auto-generated DLL loading setup for Windows\nimport sys\nimport os\n\nif sys.platform == 'win32' and hasattr(os, 'add_dll_directory'):\n    _dll_dirs = []\n    # Add package directory to DLL search path\n    _pkg_dir = os.path.dirname(__file__)\n    if _pkg_dir and os.path.isdir(_pkg_dir):\n        _dll_dirs.append(_pkg_dir)\n    # Add conda Library/bin to DLL search path\n    _prefix = os.environ.get('CONDA_PREFIX', '')\n    if not _prefix:\n        # Also check PREFIX (used during conda-build tests)\n        _prefix = os.environ.get('PREFIX', '')\n    if _prefix:\n        _lib_bin = os.path.join(_prefix, 'Library', 'bin')\n        if os.path.isdir(_lib_bin):\n            _dll_dirs.append(_lib_bin)\n        # Also check Library/lib for some DLLs\n        _lib_lib = os.path.join(_prefix, 'Library', 'lib')\n        if os.path.isdir(_lib_lib):\n            _dll_dirs.append(_lib_lib)\n    # Add all collected directories\n    for _d in _dll_dirs:\n        try:\n            os.add_dll_directory(_d)\n        except Exception:\n            pass\n\n''')" > "%INIT_FILE%"

rem Append original content if backup exists
if exist "%INIT_BAK%" (
    type "%INIT_BAK%" >> "%INIT_FILE%"
    del "%INIT_BAK%"
)

echo __init__.py created successfully
echo.
echo First 25 lines of __init__.py:
type "%INIT_FILE%" | findstr /N "^" | findstr "^[1-9]: ^1[0-9]: ^2[0-5]:"

echo Build completed successfully!
