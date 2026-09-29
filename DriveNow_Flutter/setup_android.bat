@echo off
REM One-time setup for Windows. Double-click or run from this folder.
cd /d "%~dp0"

echo === 1/3 Generating Android project files ===
call flutter create . --project-name drivenow --org ph.edu.mseuf --platforms android
if errorlevel 1 goto :error

echo === 2/3 Downloading packages ===
call flutter pub get
if errorlevel 1 goto :error

echo === 3/3 Applying DriveNow Android settings ===
call dart run tool/setup_android.dart
if errorlevel 1 goto :error

echo.
echo Setup complete! Connect your Android phone (USB debugging ON) and run:
echo     flutter run
pause
exit /b 0

:error
echo.
echo Setup failed. Make sure Flutter is installed and "flutter doctor" shows no Android errors.
pause
exit /b 1
