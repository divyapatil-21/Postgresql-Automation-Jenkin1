@echo off

echo.
echo =====================================
echo STARTING MYSQL
echo =====================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\powershell\start_mysql.ps1"

if errorlevel 1 (
    echo.
    echo MYSQL START FAILED
    exit /b 1
)

echo.
echo MYSQL START SUCCESSFUL
echo.