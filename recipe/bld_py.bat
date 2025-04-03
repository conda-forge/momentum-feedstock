@echo on

nvcc --version

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_ENABLE_SIMD=OFF ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON

python -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
