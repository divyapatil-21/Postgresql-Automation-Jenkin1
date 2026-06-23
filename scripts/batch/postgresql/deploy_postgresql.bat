@echo off
setlocal

echo ===================================
echo DEPLOY POSTGRESQL
echo ===================================

call "%~dp0initialize_logs.bat"
if errorlevel 1 exit /b 1

echo.
echo [1/4] Installing / Validating PostgreSQL...
powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\postgresql\install_windows.ps1"
if errorlevel 1 exit /b 1

echo.
echo [2/4] Starting PostgreSQL service...
powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\postgresql\start_postgresql.ps1"
if errorlevel 1 exit /b 1

echo.
echo [3/4] Creating database...
call "%~dp0create_database.bat"
if errorlevel 1 exit /b 1

echo.
echo [4/4] Running Liquibase migrations...
call "%~dp0run_liquibase.bat"
if errorlevel 1 exit /b 1

echo.
echo ===================================
echo DEPLOYMENT SUCCESSFUL
echo ===================================

exit /b 0
