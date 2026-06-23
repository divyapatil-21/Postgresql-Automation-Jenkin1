@echo off
setlocal

echo.
echo =====================================
echo VALIDATING CSV FILES
echo =====================================
echo.

python scripts\python\mysql\validate_csv.py

if errorlevel 1 (
    echo.
    echo CSV VALIDATION FAILED
    exit /b 1
)

echo.
echo CSV VALIDATION SUCCESSFUL
echo.

exit /b 0