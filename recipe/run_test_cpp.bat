@echo on

cmake tests ^
  -B tests/build ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX%
if errorlevel 1 exit 1

cmake --build build --parallel --config Release
if errorlevel 1 exit 1
