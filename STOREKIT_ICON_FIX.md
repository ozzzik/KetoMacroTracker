# StoreKit Purchase Dialog Icon Not Showing - Fix Guide

## The Issue

The app icon is not appearing in the StoreKit purchase confirmation dialog (the native iOS subscription dialog that appears when you tap "Subscribe").

## Root Cause

The icon in StoreKit purchase dialogs is automatically extracted by iOS from the app bundle's `CFBundleIcons` configuration in Info.plist. Since your project uses `GENERATE_INFOPLIST_FILE = YES`, the Info.plist is auto-generated, and the icon should be included automatically via `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.

However, sometimes the auto-generated Info.plist doesn't properly include the icon configuration, especially if:
1. The asset catalog isn't being processed correctly
2. The icon files aren't being copied to the app bundle
3. The CFBundleIcons dictionary isn't being generated

## Comparison with WaterReminder App

WaterReminder likely has one of these differences:
1. **Explicit Info.plist**: May have a manual Info.plist file with explicit `CFBundleIcons` configuration
2. **Different Build Settings**: May have different asset catalog compiler settings
3. **Icon File Format**: May have the icon in a different format or location

## Solution: Ensure Icon is in Generated Info.plist

### Option 1: Verify Asset Catalog Processing (Recommended First Step)

1. **Clean Build Folder**: Product → Clean Build Folder (Cmd+Shift+K)
2. **Delete Derived Data**: 
   - Xcode → Preferences → Locations
   - Click arrow next to Derived Data
   - Delete your project's folder
3. **Rebuild**: Product → Build (Cmd+B)
4. **Archive**: Product → Archive
5. **Check Generated Info.plist**:
   - Window → Organizer → Right-click archive → Show in Finder
   - Right-click `.xcarchive` → Show Package Contents
   - Navigate to `Products/Applications/KetoMacroTracker.app/Info.plist`
   - Open with TextEdit or `plutil -p Info.plist`
   - Look for `CFBundleIcons` key - it should contain icon file references

### Option 2: Create Explicit Info.plist (If Option 1 Doesn't Work)

If the auto-generated Info.plist doesn't include the icon, create a manual Info.plist:

1. **Create Info.plist file**:
   - File → New → File → Property List
   - Name it `Info.plist`
   - Place it in `KetoMacroTracker/` folder

2. **Add CFBundleIcons configuration**:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleIcons</key>
       <dict>
           <key>CFBundlePrimaryIcon</key>
           <dict>
               <key>CFBundleIconFiles</key>
               <array>
                   <string>AppIcon</string>
               </array>
           </dict>
       </dict>
   </dict>
   </plist>
   ```

3. **Update Build Settings**:
   - Select project → Target → Build Settings
   - Search for "Info.plist"
   - Set `INFOPLIST_FILE` to `KetoMacroTracker/Info.plist`
   - Set `GENERATE_INFOPLIST_FILE` to `NO`

### Option 3: Verify Icon Files Are in App Bundle

1. **Check Archive Contents**:
   - After archiving, check: `Products/Applications/KetoMacroTracker.app/`
   - Look for icon files like:
     - `AppIcon60x60@2x.png`
     - `AppIcon60x60@3x.png`
     - `AppIcon20x20@2x.png`
     - etc.

2. **If Icon Files Are Missing**:
   - Verify `Assets.xcassets` is in "Copy Bundle Resources" build phase
   - Check that `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in build settings

## Verification Steps

1. **Build and Archive** the app
2. **Install on Device** (not simulator - StoreKit dialogs work differently on device)
3. **Test Purchase Flow**:
   - Go to subscription screen
   - Tap "Subscribe"
   - Check if icon appears in the purchase confirmation dialog

## Common Issues

1. **Simulator vs Device**: StoreKit purchase dialogs may show icons differently on simulator vs device
2. **TestFlight vs Production**: Icons may appear in TestFlight but not in sandbox testing
3. **Icon Format**: Ensure icon is PNG, RGB color space, no alpha channel
4. **Icon Size**: Ensure 1024x1024 icon exists and is properly referenced

## Expected Behavior

When you tap "Subscribe" in the app, the native iOS purchase dialog should show:
- Your app icon (left side)
- Subscription name
- Price
- "Confirm with Side Button" prompt

If the icon is missing, it will show a generic placeholder icon instead.

