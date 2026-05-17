#!/bin/bash
# Run the app on a connected device with your Gemini API key.
# Setup (once):
#   cp keys/dart_defines.example.json keys/dart_defines.json
#   Edit keys/dart_defines.json and paste your API key from aistudio.google.com/apikey

set -e
cd "$(dirname "$0")/.."

"$(dirname "$0")/ensure_gemini_keys.sh"

flutter run --dart-define-from-file=keys/dart_defines.json "$@"
