#!/usr/bin/env bash
# One-time setup for macOS / Linux:  ./setup_android.sh
set -e
cd "$(dirname "$0")"

echo "=== 1/3 Generating Android project files ==="
flutter create . --project-name drivenow --org ph.edu.mseuf --platforms android

echo "=== 2/3 Downloading packages ==="
flutter pub get

echo "=== 3/3 Applying DriveNow Android settings ==="
dart run tool/setup_android.dart

echo
echo "Setup complete! Connect your Android phone (USB debugging ON) and run:"
echo "    flutter run"
