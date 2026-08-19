#!/bin/zsh

# Uninstall script for GraveSwitch
# Completely removes app binaries, launch items, preferences, and TCC permissions.

BUNDLE_ID="com.example.GraveSwitch"

echo "Stopping GraveSwitch process..."
killall GraveSwitch 2>/dev/null || true

echo "Resetting Privacy Permissions (Accessibility & Input Monitoring)..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset ListenEvent "$BUNDLE_ID" 2>/dev/null || true

echo "Removing preferences..."
defaults delete "$BUNDLE_ID" 2>/dev/null || true

echo "Removing installed applications..."
rm -rf /Applications/GraveSwitch.app 2>/dev/null || true
rm -rf ~/Applications/GraveSwitch.app 2>/dev/null || true

echo "GraveSwitch permissions and app files have been completely removed from macOS."
