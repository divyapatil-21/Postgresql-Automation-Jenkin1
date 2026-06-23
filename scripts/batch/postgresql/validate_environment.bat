@echo off
setlocal

echo ============================================
echo ENVIRONMENT VALIDATION
echo ============================================

echo.
echo --- Python ---
python --version
if errorlevel 1 (
    echo FAIL: Python not found
    exit /b 1
)

echo.
echo --- Java ---
java -version 2>&1
if errorlevel 1 (
    echo FAIL: Java not found
    exit /b 1
)

echo.
echo --- pip ---
pip --version
if errorlevel 1 (
    echo FAIL: pip not found
    exit /b 1
)

echo.
echo --- PostgreSQL Client (project folder) ---
set PG_BIN=%~dp0..\..\..\databases\postgresql\bin
if exist "%PG_BIN%\psql.exe" (
    "%PG_BIN%\psql.exe" --version
    echo PostgreSQL client found in project folder
) else (
    echo WARN: psql not in project folder - run setup pipeline first
)

echo.
echo ============================================
echo ENVIRONMENT VALIDATION COMPLETED
echo ============================================

exit /b 0