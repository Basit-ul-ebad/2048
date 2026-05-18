# Run the app with Gemini API key (Windows PowerShell).
# Setup (once):
#   Copy keys/dart_defines.example.json to keys/dart_defines.json
#   Edit keys/dart_defines.json and paste your API key from aistudio.google.com/apikey
#
# Usage (from project folder):
#   .\scripts\run_with_gemini.ps1

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

& (Join-Path $PSScriptRoot "ensure_gemini_keys.ps1")

$keyFile = Join-Path "keys" "dart_defines.json"
if (-not (Test-Path $keyFile)) {
  Write-Error "keys/dart_defines.json not found. Add your GEMINI_API_KEY there."
  exit 1
}

Write-Host "Running flutter with keys/dart_defines.json ..."
flutter run --dart-define-from-file=keys/dart_defines.json @args
