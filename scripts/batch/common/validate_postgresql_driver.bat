@echo off
setlocal

set PROJECT_ROOT=%~dp0..\..\..

if not exist "%PROJECT_ROOT%\tools\drivers\postgresql.jar" (
    echo PostgreSQL JDBC Driver not found
    exit /b 1
)

echo PostgreSQL JDBC Driver validated

exit /b 0