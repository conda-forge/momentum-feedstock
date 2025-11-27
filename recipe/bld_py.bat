@echo on

where nvcc >nul 2>&1 && nvcc --version

:: Force Ninja generator to avoid VS CUDA integration issues
set CMAKE_GENERATOR=Ninja

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_BUILD_IO_USD=OFF ^
    -DMOMENTUM_BUILD_RENDERER=OFF ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON ^
    -DCMAKE_POLICY_DEFAULT_CMP0148=NEW ^
    -DPYBIND11_FINDPYTHON=ON

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation
