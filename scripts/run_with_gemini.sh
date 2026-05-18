#!/bin/bash
# Run the app on a connected device with your Gemini API key.
# Mac/Linux: ./scripts/run_with_gemini.sh
# Windows PowerShell: .\scripts\run_with_gemini.ps1
# Windows CMD: scripts\run_with_gemini.bat
#
# Setup (once):
#   cp keys/dart_defines.example.json keys/dart_defines.json
#   Edit keys/dart_defines.json and paste your API key from aistudio.google.com/apikey

set -e
cd "$(dirname "$0")/.."

"$(dirname "$0")/ensure_gemini_keys.sh"

flutter run --dart-define-from-file=keys/dart_defines.json "$@"
