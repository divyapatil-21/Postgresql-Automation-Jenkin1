@echo off
setlocal
call "%~dp0postgresql\validate_python_requirements.bat"
exit /b %ERRORLEVEL%
