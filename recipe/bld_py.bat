@echo on

echo CUDA_HOME is set to: %CUDA_HOME%

echo PATH is set to: %PATH%

@REM set CMAKE_ARGS=%CMAKE_ARGS% ^
@REM     -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
@REM     -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
@REM     -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
@REM if errorlevel 1 exit 1

%PYTHON% -m pip install --no-deps --ignore-installed . -vv --prefix=%PREFIX%
if errorlevel 1 exit 1
