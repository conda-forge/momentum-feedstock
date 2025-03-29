@echo on

echo CUDA_HOME is set to: %CUDA_HOME%

echo PATH is set to: %PATH%

echo CMAKE_ARGS before is set to: %CMAKE_ARGS%

set "CMAKE_ARGS=%CMAKE_ARGS:\=\\%"

echo CMAKE_ARGS after is set to: %CMAKE_ARGS%

set CMAKE_ARGS="%CMAKE_ARGS%" ^
    -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
    -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
    -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

%PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
if errorlevel 1 exit 1
