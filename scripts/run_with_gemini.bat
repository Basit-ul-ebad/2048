@echo off
REM Run the app with Gemini API key (Windows CMD).
REM Usage: scripts\run_with_gemini.bat

cd /d "%~dp0\.."

if not exist "keys\dart_defines.json" (
  if exist "keys\dart_defines.example.json" (
    copy "keys\dart_defines.example.json" "keys\dart_defines.json" >nul
    echo Created keys\dart_defines.json - add your GEMINI_API_KEY
  ) else (
    echo ERROR: keys\dart_defines.example.json not found.
    exit /b 1
  )
)

if not exist "keys\dart_defines.json" (
  echo ERROR: keys\dart_defines.json not found.
  exit /b 1
)

echo Running flutter with keys/dart_defines.json ...
flutter run --dart-define-from-file=keys/dart_defines.json %*
