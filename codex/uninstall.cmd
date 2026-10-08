@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
set "naiyou_exit=%errorlevel%"
echo.
pause
exit /b %naiyou_exit%
