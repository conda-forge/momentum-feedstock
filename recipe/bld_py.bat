@echo on

set CMAKE_ARGS=%CMAKE_ARGS% ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

%PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
if errorlevel 1 exit 1
