@echo off
REM Enable Firebase Analytics DebugView on Android (Windows).
set PACKAGE=com.basitulebad.twozerofoureight
echo Enabling debug mode for %PACKAGE%
adb shell setprop debug.firebase.analytics.app %PACKAGE%
echo.
echo Done. Force-stop the app, run flutter run, then check Firebase DebugView.
echo Disable: adb shell setprop debug.firebase.analytics.app .none.
