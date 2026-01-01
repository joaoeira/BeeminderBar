#!/bin/bash
# Install script for BeeminderBar
# Builds the app and copies it to /Applications

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="BeeminderBar"

echo "Building $APP_NAME..."
cd "$PROJECT_DIR"

xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Debug \
    build \
    2>&1 | grep -E "(error:|warning:|BUILD)" || true

# Find the built app
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA" -name "$APP_NAME.app" -path "*/Debug/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

echo "Found app at: $APP_PATH"

# Kill running instance
pkill -x "$APP_NAME" 2>/dev/null || true

# Copy to Applications
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_PATH" /Applications/

echo "Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"

echo "Done! $APP_NAME is now running from /Applications"
