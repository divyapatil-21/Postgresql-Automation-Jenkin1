@echo off
setlocal
call "%~dp0postgresql\install_python_requirements.bat"
exit /b %ERRORLEVEL%
