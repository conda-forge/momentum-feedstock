@echo on

where nvcc >nul 2>&1 && nvcc --version

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_BUILD_IO_USD=OFF ^
    -DMOMENTUM_BUILD_RENDERER=ON ^
    -DMOMENTUM_BUILD_TESTING=OFF ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON

%PYTHON% -m pip install . -vv --no-deps --no-build-isolation

REM Run Python unit tests
REM Change to a different directory to ensure we import the installed package
cd ..
set MOMENTUM_MODELS_PATH=%SRC_DIR%\momentum\
%PYTHON% -m pytest --pyargs pymomentum.test -v
