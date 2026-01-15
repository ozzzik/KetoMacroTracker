# StoreKit Icon Issue - Comparison with WaterReminder

## Current Status

Your app has:
- ✅ Icon files in app bundle: `AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png`
- ✅ `CFBundleIcons` in Info.plist with `CFBundleIconName = "AppIcon"`
- ✅ Asset catalog properly configured
- ✅ Icon files exist in archive

**But**: Icon still shows as generic placeholder in StoreKit purchase dialog.

## Key Differences to Check with WaterReminder

### 1. Info.plist Configuration

**Your App (KetoMacroTracker)**:
```xml
CFBundleIcons = {
    CFBundlePrimaryIcon = {
        CFBundleIconFiles = ["AppIcon60x60"]
        CFBundleIconName = "AppIcon"
    }
}
```

**WaterReminder might have**:
- More complete `CFBundleIconFiles` array (including all sizes)
- Different `CFBundleIconName` format
- Additional icon configuration

### 2. Icon File Format

**Check WaterReminder's icon files**:
- Are they PNG with specific color profile?
- Do they have alpha channel?
- What are the exact dimensions?

**Your icons should be**:
- PNG format
- RGB color space (sRGB)
- No alpha channel
- Exact dimensions as specified

### 3. Asset Catalog vs Individual Files

**Your App**: Uses asset catalog (`Assets.car`)

**WaterReminder might**:
- Use individual icon files in bundle (not asset catalog)
- Have explicit icon files referenced in Info.plist
- Use different asset catalog configuration

### 4. Build Settings

**Check WaterReminder's build settings**:
- `ASSETCATALOG_COMPILER_APPICON_NAME` - should be "AppIcon"
- `GENERATE_INFOPLIST_FILE` - might be NO (manual Info.plist)
- `INFOPLIST_FILE` - might point to explicit Info.plist

## Most Likely Solution

The issue is likely that **StoreKit needs the icon to be accessible via a specific name or format**. 

### Try This First:

1. **Verify Icon is Valid**:
   ```bash
   # Check icon file
   file AppIcon-1024.png
   # Should show: PNG image data, 1024 x 1024, RGB, non-interlaced
   ```

2. **Check Icon Has No Alpha**:
   - Open `AppIcon-1024.png` in Preview
   - Tools → Show Inspector
   - Check "Alpha" - should be "No"

3. **Re-export Icon**:
   - Open your icon in design tool
   - Export as PNG
   - **Uncheck "Alpha Channel"**
   - Color Profile: sRGB
   - Save as `AppIcon-1024.png`
   - Replace in `Assets.xcassets/AppIcon.appiconset/`

4. **Clean and Rebuild**:
   - Product → Clean Build Folder
   - Delete Derived Data
   - Product → Archive
   - Test on **physical device** (not simulator)

### Alternative: Explicit Info.plist

If asset catalog approach doesn't work, create explicit Info.plist:

1. Create `Info.plist` in `KetoMacroTracker/` folder
2. Add complete icon configuration:
   ```xml
   <key>CFBundleIcons</key>
   <dict>
       <key>CFBundlePrimaryIcon</key>
       <dict>
           <key>CFBundleIconFiles</key>
           <array>
               <string>AppIcon</string>
           </array>
           <key>CFBundleIconName</key>
           <string>AppIcon</string>
       </dict>
   </dict>
   ```
3. Set `GENERATE_INFOPLIST_FILE = NO`
4. Set `INFOPLIST_FILE = KetoMacroTracker/Info.plist`

## Testing

**Important**: Test on **physical device**, not simulator. StoreKit purchase dialogs behave differently:
- **Simulator**: May show generic icon (known issue)
- **Device**: Should show actual app icon
- **TestFlight**: Should show actual app icon

## Why WaterReminder Works

WaterReminder likely has one of these:
1. **Manual Info.plist** with explicit icon configuration
2. **Icon files directly in bundle** (not just asset catalog)
3. **Different icon format** (no alpha, specific color profile)
4. **Older build system** that processes icons differently

## Next Steps

1. **Compare Info.plist**: Check WaterReminder's Info.plist structure
2. **Compare Icon Files**: Check WaterReminder's icon file format
3. **Test on Device**: Ensure you're testing on physical device, not simulator
4. **Check TestFlight**: Icon might appear in TestFlight even if not in sandbox

