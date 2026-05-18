#!/bin/bash
# Enable Firebase Analytics DebugView on a connected Android device.
# Run this BEFORE starting the app, then fully restart the app.
#
# Usage:
#   ./scripts/enable_firebase_debug.sh
#   flutter run

set -e
PACKAGE="com.basitulebad.twozerofoureight"

echo "Enabling Firebase Analytics debug mode for: $PACKAGE"
adb shell setprop debug.firebase.analytics.app "$PACKAGE"
echo ""
echo "Done. Now:"
echo "  1. Force-stop the app on your phone"
echo "  2. Run: flutter run"
echo "  3. Open Firebase Console → Analytics → DebugView"
echo "  4. Pick your device in the Debug Device dropdown"
echo "  5. In app: Settings → Send test analytics event"
echo ""
echo "To disable debug mode:"
echo "  adb shell setprop debug.firebase.analytics.app .none."
