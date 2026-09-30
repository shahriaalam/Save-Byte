@echo off
title SaveBite - Android Simulator Launcher
echo ========================================================
echo          SaveBite - Android Simulator Launcher
echo ========================================================
echo.
echo [1/3] Opening Google Pixel 7 Android Simulator window...
set "JAVA_HOME=C:\Users\shahr\AppData\Local\Android\jdk"
set "ANDROID_HOME=C:\Users\shahr\AppData\Local\Android\Sdk"
set "PATH=C:\Users\shahr\AppData\Local\Android\jdk\bin;C:\Users\shahr\AppData\Local\Android\Sdk\emulator;C:\Users\shahr\AppData\Local\Android\Sdk\platform-tools;D:\flutter\bin;%PATH%"

cd /d "C:\Users\shahr\AppData\Local\Android\Sdk\emulator"
start "" emulator.exe -avd SaveBitePixel

echo [2/3] Waiting for Android device to boot...
cd /d "d:\Save Byte"
adb wait-for-device

echo [3/3] Launching SaveBite Flutter App (Hot Reload enabled)...
echo Press 'r' to hot reload, 'R' to hot restart, 'q' to quit.
echo ========================================================
flutter run -d emulator-5554
pause
