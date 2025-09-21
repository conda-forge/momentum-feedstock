@echo on
setlocal EnableExtensions

rem Prefer Ninja & parallel builds on Windows
set "CMAKE_GENERATOR=Ninja"
set "CMAKE_BUILD_PARALLEL_LEVEL=%CPU_COUNT%"

cmake %SRC_DIR% ^
  %CMAKE_ARGS% ^
  -G Ninja ^
  -B build ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SHARED_LIBS=ON ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DMOMENTUM_BUILD_EXAMPLES=ON ^
  -DMOMENTUM_BUILD_PYMOMENTUM=OFF ^
  -DMOMENTUM_BUILD_TESTING=ON ^
  -DMOMENTUM_INSTALL_EXAMPLES=ON ^
  -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
  -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
  -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

cmake --build build --parallel
if errorlevel 1 exit 1

cmake --install build
if errorlevel 1 exit 1

ctest --test-dir build --output-on-failure
if errorlevel 1 exit 1
