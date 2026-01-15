#!/bin/bash
# Script to verify icon configuration in Xcode archive

echo "🔍 Icon Configuration Verification Script"
echo "=========================================="
echo ""

# Find the most recent archive
ARCHIVE_PATH=$(find ~/Library/Developer/Xcode/Archives -name "*.xcarchive" -type d -maxdepth 1 | sort -r | head -1)

if [ -z "$ARCHIVE_PATH" ]; then
    echo "❌ No archive found. Please archive the app first:"
    echo "   Product → Archive in Xcode"
    exit 1
fi

echo "📦 Found archive: $ARCHIVE_PATH"
echo ""

APP_PATH="$ARCHIVE_PATH/Products/Applications/KetoMacroTracker.app"
INFO_PLIST="$APP_PATH/Info.plist"

# Check if Info.plist exists
if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Info.plist not found in archive"
    exit 1
fi

echo "✅ Info.plist found"
echo ""

# Check for CFBundleIcons
echo "🔍 Checking CFBundleIcons configuration..."
if plutil -extract CFBundleIcons raw "$INFO_PLIST" 2>/dev/null; then
    echo "✅ CFBundleIcons found in Info.plist"
    echo ""
    echo "CFBundleIcons content:"
    plutil -extract CFBundleIcons xml1 "$INFO_PLIST" -o - | head -20
    echo ""
else
    echo "❌ CFBundleIcons NOT found in Info.plist"
    echo "   This is the problem! The icon won't show in StoreKit dialogs."
    exit 1
fi

# Check for icon files in app bundle
echo "🔍 Checking for icon files in app bundle..."
ICON_FILES=$(find "$APP_PATH" -name "AppIcon*.png" -type f)

if [ -z "$ICON_FILES" ]; then
    echo "❌ No icon files found in app bundle"
    echo "   Expected files like: AppIcon60x60@2x.png"
else
    echo "✅ Icon files found:"
    echo "$ICON_FILES" | while read -r file; do
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        echo "   - $(basename "$file") ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "${size}B"))"
    done
fi

echo ""
echo "✅ Verification complete!"

