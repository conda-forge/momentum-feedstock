@echo on

cmake %SRC_DIR% ^
  %CMAKE_ARGS% ^
  -B build ^
  -DBUILD_SHARED_LIBS=ON ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DMOMENTUM_BUILD_EXAMPLES=ON ^
  -DMOMENTUM_BUILD_IO_USD=OFF ^
  -DMOMENTUM_BUILD_PYMOMENTUM=OFF ^
  -DMOMENTUM_BUILD_RENDERER=ON ^
  -DMOMENTUM_BUILD_TESTING=OFF ^
  -DMOMENTUM_INSTALL_EXAMPLES=ON ^
  -DMOMENTUM_USE_SYSTEM_GOOGLETEST=ON ^
  -DMOMENTUM_USE_SYSTEM_PYBIND11=ON ^
  -DMOMENTUM_USE_SYSTEM_RERUN_CPP_SDK=ON
if errorlevel 1 exit 1

cmake --build build --parallel --config Release
if errorlevel 1 exit 1

cmake --build build --parallel --config Release --target install
if errorlevel 1 exit 1

ctest --test-dir build --output-on-failure --build-config Release
if errorlevel 1 exit 1
