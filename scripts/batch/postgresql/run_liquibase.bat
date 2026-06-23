@echo off
setlocal

echo ===================================
echo RUN LIQUIBASE MIGRATIONS
echo ===================================

set PROJECT_ROOT=%~dp0..\..\..

:: Discover Liquibase executable dynamically
set LIQUIBASE_EXE=
if exist "%PROJECT_ROOT%\tools\liquibase\liquibase.bat" (
    set LIQUIBASE_EXE=%PROJECT_ROOT%\tools\liquibase\liquibase.bat
) else (
    where liquibase >nul 2>&1
    if not errorlevel 1 (
        set LIQUIBASE_EXE=liquibase
    )
)

if "%LIQUIBASE_EXE%"=="" (
    echo ERROR: Liquibase not found in tools\liquibase\ or PATH
    exit /b 1
)

:: Discover PostgreSQL JDBC driver dynamically
set DRIVER_JAR=
for %%F in ("%PROJECT_ROOT%\tools\drivers\postgresql*.jar") do (
    set DRIVER_JAR=%%F
)

if "%DRIVER_JAR%"=="" (
    echo ERROR: PostgreSQL JDBC driver not found in tools\drivers\
    echo Please run install_tools to download the driver
    exit /b 1
)

echo Liquibase : %LIQUIBASE_EXE%
echo Driver    : %DRIVER_JAR%
echo.

cd /d "%PROJECT_ROOT%\liquibase\postgresql"

"%LIQUIBASE_EXE%" ^
    --defaultsFile=liquibase.properties ^
    --classpath="%DRIVER_JAR%" ^
    update

if errorlevel 1 (
    echo FAILED: Liquibase migration failed
    exit /b 1
)

echo.
echo Liquibase Migrations Completed Successfully

exit /b 0
