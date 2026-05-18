# Ensures keys/dart_defines.json exists (copies from example if missing).
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$keyFile = Join-Path "keys" "dart_defines.json"
$exampleFile = Join-Path "keys" "dart_defines.json.example"

if (-not (Test-Path $keyFile)) {
  if (Test-Path $exampleFile) {
    Copy-Item $exampleFile $keyFile
    Write-Host "Created keys/dart_defines.json - paste your GEMINI_API_KEY from aistudio.google.com/apikey"
  } else {
    Write-Error "ERROR: keys/dart_defines.json.example not found."
    exit 1
  }
}
