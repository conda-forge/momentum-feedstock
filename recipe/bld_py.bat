@echo on

where nvcc >nul 2>&1 && nvcc --version

:: Force Ninja generator to avoid VS CUDA integration issues
set CMAKE_GENERATOR=Ninja

:: Get Python prefix to help FindPython locate the library
for /f "usebackq tokens=*" %%a in (`%PYTHON% -c "import sys; print(sys.prefix)"`) do set PYTHON_PREFIX=%%a
:: Convert backslashes to forward slashes for CMake
set PYTHON_PREFIX=%PYTHON_PREFIX:\=/%

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_BUILD_IO_USD=OFF ^
    -DMOMENTUM_BUILD_RENDERER=OFF ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON ^
    -DCMAKE_POLICY_DEFAULT_CMP0148=NEW ^
    -DPYBIND11_FINDPYTHON=ON ^
    -DPython_ROOT_DIR="%PYTHON_PREFIX%" ^
    -DPython3_ROOT_DIR="%PYTHON_PREFIX%" ^
    -DPython_FIND_STRATEGY=LOCATION ^
    -DPython3_FIND_STRATEGY=LOCATION ^
    -DPython_FIND_REGISTRY=NEVER ^
    -DPython3_FIND_REGISTRY=NEVER

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation
