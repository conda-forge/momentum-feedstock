@echo on

rem Install this output's wheel from the pymomentum-build staging output.
if not exist "%SRC_DIR%\pymomentum_wheels\%PKG_NAME%\*.whl" exit 1
for %%W in ("%SRC_DIR%\pymomentum_wheels\%PKG_NAME%\*.whl") do (
    "%PYTHON%" -m pip install "%%~W" -vv --no-deps --no-index
    if errorlevel 1 exit 1
)
