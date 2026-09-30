@echo off
title Android Emulator - SaveBite
echo ==============================================
echo   Starting SaveBite Android Emulator (Pixel 7)
echo ==============================================
set "ANDROID_HOME=C:\Users\shahr\AppData\Local\Android\Sdk"
set "PATH=C:\Users\shahr\AppData\Local\Android\Sdk\emulator;C:\Users\shahr\AppData\Local\Android\Sdk\platform-tools;%PATH%"
cd /d "C:\Users\shahr\AppData\Local\Android\Sdk\emulator"
start "" emulator.exe -avd SaveBitePixel
echo Emulator window is opening on your desktop...
timeout /t 4
