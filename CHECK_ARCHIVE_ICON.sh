#!/bin/bash
# Script to check if icon is in archive

ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"

echo "🔍 Finding most recent archive..."
LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -maxdepth 1 2>/dev/null | sort -r | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo "❌ No archives found in $ARCHIVE_DIR"
    exit 1
fi

echo "📦 Archive: $LATEST_ARCHIVE"
echo ""

APP_BUNDLE="$LATEST_ARCHIVE/Products/Applications/KetoMacroTracker.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App bundle not found: $APP_BUNDLE"
    exit 1
fi

echo "📊 Checking Assets.car..."
ASSETS_CAR="$APP_BUNDLE/Assets.car"
if [ -f "$ASSETS_CAR" ]; then
    SIZE=$(ls -lh "$ASSETS_CAR" | awk '{print $5}')
    SIZE_BYTES=$(stat -f%z "$ASSETS_CAR" 2>/dev/null || stat -c%s "$ASSETS_CAR" 2>/dev/null)
    echo "✅ Assets.car exists: $SIZE ($SIZE_BYTES bytes)"
    
    if [ "$SIZE_BYTES" -gt 51200 ]; then
        echo "✅ Size is good (> 50KB) - icon should be included"
    else
        echo "⚠️  Size is small (< 50KB) - icon might not be included"
    fi
else
    echo "❌ Assets.car NOT FOUND - icon is not in archive!"
fi

echo ""
echo "📋 Checking for extracted icon files..."
ICON_FILES=$(find "$APP_BUNDLE" -name "*Icon*.png" -o -name "*icon*.png" 2>/dev/null | head -5)
if [ -n "$ICON_FILES" ]; then
    echo "✅ Found icon files:"
    echo "$ICON_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            SIZE=$(ls -lh "$file" | awk '{print $5}')
            echo "   - $(basename "$file"): $SIZE"
        fi
    done
else
    echo "ℹ️  No extracted icon files found (this is normal - icons are in Assets.car)"
fi

echo ""
echo "📅 Archive date:"
ls -ld "$LATEST_ARCHIVE" | awk '{print $6, $7, $8}'
