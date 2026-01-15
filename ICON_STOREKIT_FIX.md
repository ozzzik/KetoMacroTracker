# StoreKit Purchase Dialog Icon Fix

## The Issue
The app icon is not appearing in StoreKit purchase dialogs (the native iOS subscription confirmation dialog).

## Root Cause
StoreKit automatically extracts the app icon from the app bundle's `CFBundleIcons` configuration. The icon should appear automatically, but sometimes it doesn't due to:
1. Icon not being properly included in the app bundle
2. StoreKit sandbox limitations (icons may not show in sandbox testing)
3. Icon format/compression issues
4. Caching issues

## Current Configuration ✅
- ✅ Icon files exist in `Assets.xcassets/AppIcon.appiconset/`
- ✅ `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in build settings
- ✅ `GENERATE_INFOPLIST_FILE = YES` (auto-generates Info.plist with CFBundleIcons)
- ✅ Icon format: PNG, RGB, 1024x1024

## Solution: Verify Icon is in App Bundle

### Step 1: Clean Build
1. In Xcode: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/KetoMacroTracker-*
   ```

### Step 2: Archive and Verify
1. **Product → Archive** in Xcode
2. After archive completes:
   - **Window → Organizer** (Cmd+Shift+9)
   - Right-click archive → **Show in Finder**
   - Right-click `.xcarchive` → **Show Package Contents**
   - Navigate to: `Products/Applications/KetoMacroTracker.app/`
   - Check for icon files:
     - `AppIcon60x60@2x.png`
     - `AppIcon60x60@3x.png`
     - `AppIcon76x76@2x~ipad.png`
     - etc.

### Step 3: Verify Info.plist
1. In the archive, open: `Products/Applications/KetoMacroTracker.app/Info.plist`
2. Check for `CFBundleIcons` key:
   ```xml
   <key>CFBundleIcons</key>
   <dict>
       <key>CFBundlePrimaryIcon</key>
       <dict>
           <key>CFBundleIconFiles</key>
           <array>
               <string>AppIcon60x60</string>
           </array>
           <key>CFBundleIconName</key>
           <string>AppIcon</string>
       </dict>
   </dict>
   ```

### Step 4: Test on Device (Not Simulator)
**Important**: StoreKit purchase dialogs may not show icons properly in:
- iOS Simulator
- Sandbox testing environment

**The icon will appear in**:
- TestFlight builds
- Production App Store builds
- Real device testing (not simulator)

### Step 5: Upload to TestFlight
1. Distribute the archive to App Store Connect
2. Wait for processing (5-15 minutes)
3. Install via TestFlight
4. Test the purchase flow - icon should appear

## If Icon Still Doesn't Appear

### Option 1: Verify Icon File Format
```bash
# Check icon format
file KetoMacroTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
# Should show: PNG image data, 1024 x 1024, RGB, non-interlaced

# Check for alpha channel (should be NO alpha)
sips -g hasAlpha KetoMacroTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
# Should show: hasAlpha: no
```

### Option 2: Re-export Icon
1. Open icon in design tool (Figma, Sketch, Photoshop)
2. Export as PNG with:
   - RGB color space (not RGBA)
   - No alpha channel
   - Exactly 1024x1024 pixels
   - Optimized compression
3. Replace `AppIcon-1024.png` in asset catalog
4. Clean and rebuild

### Option 3: Check Build Settings
1. Select project → Target → Build Settings
2. Search for "Asset Catalog"
3. Verify:
   - `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
   - `ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS = YES` (optional)

## Important Notes

1. **Sandbox Limitation**: Icons may not appear in StoreKit sandbox testing. This is a known iOS limitation.

2. **TestFlight/Production**: Icons will appear in TestFlight and production builds, even if they don't show in sandbox.

3. **Icon Caching**: iOS may cache the icon. Try:
   - Uninstalling and reinstalling the app
   - Restarting the device
   - Waiting a few minutes after install

4. **Icon Size**: Ensure the 1024x1024 icon is properly included. This is the icon StoreKit uses.

## Verification Checklist

- [ ] Icon files exist in asset catalog
- [ ] Icon is 1024x1024, RGB, no alpha
- [ ] `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` in build settings
- [ ] Icon files appear in archived app bundle
- [ ] `CFBundleIcons` exists in Info.plist
- [ ] Tested on real device (not simulator)
- [ ] Tested in TestFlight (not sandbox)

If all of the above are true, the icon should appear in StoreKit purchase dialogs in TestFlight and production.

