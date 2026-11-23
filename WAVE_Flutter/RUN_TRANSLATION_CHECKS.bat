@echo off
setlocal
cd /d "%~dp0"
python -m pytest translation_gateway\gateway -q
if errorlevel 1 exit /b 1
call flutter pub get
if errorlevel 1 exit /b 1
call flutter analyze
if errorlevel 1 exit /b 1
call flutter test
if errorlevel 1 exit /b 1
