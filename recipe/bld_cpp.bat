@echo on

set CMAKE_CXX_FLAGS=/utf-8

cmake %SRC_DIR% ^
  -B build ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DMOMENTUM_BUILD_EXAMPLES=OFF ^
  -DMOMENTUM_BUILD_PYMOMENTUM=OFF ^
  -DMOMENTUM_BUILD_TESTING=ON ^
  -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
  -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
  -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

cmake --build build --parallel --config Release
if errorlevel 1 exit 1

ctest --test-dir build --output-on-failure --build-config Release
if errorlevel 1 exit 1

cmake --build build --parallel --config Release --target install
if errorlevel 1 exit 1
