#!/bin/bash
# Quick script to check Assets.car in archive

echo "📦 Checking for Assets.car in archive..."
echo ""
echo "Please drag your archive's Applications folder here, then press Enter:"
read -r apps_path

if [ -z "$apps_path" ]; then
    echo "❌ No path provided"
    exit 1
fi

# Remove quotes if user added them
apps_path=$(echo "$apps_path" | sed "s/^'//; s/'$//")

ASSETS_CAR="$apps_path/KetoMacroTracker.app/Assets.car"

if [ -f "$ASSETS_CAR" ]; then
    SIZE=$(ls -lh "$ASSETS_CAR" | awk '{print $5}')
    SIZE_BYTES=$(stat -f%z "$ASSETS_CAR" 2>/dev/null || stat -c%s "$ASSETS_CAR" 2>/dev/null)
    echo "✅ Assets.car found!"
    echo "   Size: $SIZE ($SIZE_BYTES bytes)"
    echo ""
    if [ "$SIZE_BYTES" -gt 51200 ]; then
        echo "✅ Size is good (> 50KB) - icon should be included!"
    else
        echo "⚠️  Size is small (< 50KB) - icon might not be included"
    fi
else
    echo "❌ Assets.car NOT FOUND"
    echo "   Path checked: $ASSETS_CAR"
    echo ""
    echo "Listing contents of app bundle:"
    ls -la "$apps_path/KetoMacroTracker.app/" 2>/dev/null | head -10
fi
