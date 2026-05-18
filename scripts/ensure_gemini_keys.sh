#!/bin/bash
# Ensures keys/dart_defines.json exists (copies from example if missing).
set -e
cd "$(dirname "$0")/.."

if [ ! -f keys/dart_defines.json ]; then
  if [ -f keys/dart_defines.example.json ]; then
    cp keys/dart_defines.example.json keys/dart_defines.json
    echo "Created keys/dart_defines.json — paste your GEMINI_API_KEY from aistudio.google.com/apikey"
  else
    echo "ERROR: keys/dart_defines.example.json not found."
    exit 1
  fi
fi
