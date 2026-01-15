# Icon Issue - Complete Checklist (Based on Apple Guidance)

## ✅ Verified Configuration

1. **✅ App Icon in Asset Catalog**: `AppIcon.appiconset` exists with 1024x1024 icon
2. **✅ Target → General → App Icons Source**: `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` ✅
3. **✅ Not using Icon Composer**: Using asset catalog (modern approach) ✅
4. **✅ Bundle ID**: `com.whio.KetoMacroTracker` (single bundle ID) ✅
5. **✅ StoreKit Config**: NOT in scheme's LaunchAction (removed for Release) ✅

## ❓ Checks You Need to Do

### 1. **App Store Connect Icon Visibility**

**Check in App Store Connect:**
1. Go to: https://appstoreconnect.apple.com
2. My Apps → KetoMacroTracker
3. **At the very top of the app page**, next to the app name
4. **Does it show:**
   - ✅ Your actual app icon? 
   - ❌ Generic placeholder/grid?

**If placeholder in App Store Connect:**
- Icon hasn't been uploaded/processed yet
- Or build doesn't include valid icon
- **Solution**: Upload a new build with icon, wait 15-30 minutes

**If icon shows in App Store Connect:**
- The icon is valid in App Store Connect
- Issue is likely StoreKit-specific

### 2. **Test on Device (Settings → Subscriptions)**

**Check on a real device:**
1. Settings → [Your Name] → Subscriptions
2. Tap your KetoMacroTracker subscription
3. **Does it show:**
   - ✅ Your actual app icon?
   - ❌ Generic placeholder/grid?

**If placeholder here:**
- Usually matches StoreKit subscription sheet behavior
- Icon might not be propagated to StoreKit metadata yet

### 3. **Are You Testing with TestFlight Build?**

**Critical Question:**
- ❓ Are you testing with a **TestFlight build** (downloaded from TestFlight)?
- ❓ Or testing with a **local dev build** (Xcode → Run)?

**StoreKit uses App Store metadata, NOT your local bundle!**

**You MUST:**
- ✅ Archive your app
- ✅ Upload to App Store Connect
- ✅ Wait for processing (5-15 minutes)
- ✅ Install via TestFlight
- ✅ Test subscription purchase

**If testing locally:**
- StoreKit won't show your icon (it uses App Store metadata)
- This is expected behavior for local dev builds

### 4. **StoreKit Configuration in Scheme**

**Check in Xcode:**
1. Product → Scheme → Edit Scheme... (or Cmd+<)
2. Select **Run** in left sidebar
3. Go to **Options** tab
4. Under **StoreKit Configuration**:
   - ✅ Should show **"None"** (for TestFlight/production)
   - ❌ Should NOT show `Configuration.storekit`

**If it shows Configuration.storekit:**
- StoreKit uses local config (no icon metadata)
- **Fix**: Set to "None" before archiving

**For local testing only:**
- You can temporarily set it to `Configuration.storekit`
- But **remove it before archiving** for TestFlight/production

### 5. **Verify Build Has Icon**

**After archiving, check the archive:**
1. Window → Organizer (Cmd+Shift+9)
2. Right-click your archive → Show in Finder
3. Right-click `.xcarchive` → Show Package Contents
4. Navigate to: `Products/Applications/KetoMacroTracker.app/`
5. **Look for:**
   - `Assets.car` (should exist, > 50KB)
   - OR extracted icon files

**If Assets.car is missing or very small:**
- Asset catalog not compiled
- Clean build folder and re-archive

### 6. **Build Processing Status**

**Check in App Store Connect:**
1. Go to your app → TestFlight tab
2. Find your uploaded build
3. **Is it:**
   - ✅ **"Processing Complete"** (ready to test)?
   - ⏳ **"Processing"** (still working)?

**If still processing:**
- Icon won't appear until processing completes
- Wait 15-30 minutes, then check again

### 7. **Multiple Targets with Same Bundle ID**

**Check in Xcode:**
1. Select your project in Project Navigator
2. Look at the **TARGETS** list (not PROJECT)
3. **Do you have:**
   - Only `KetoMacroTracker` target?
   - OR multiple targets (KetoMacroTracker, KetoMacroTrackerDev, etc.)?

**If multiple targets with same bundle ID:**
- This can cause metadata resolution issues
- **Fix**: Use unique bundle IDs per target

## Summary Questions

Please answer these:

1. **Does the icon appear in App Store Connect** next to the app name? (Yes/No)
2. **Are you testing with a TestFlight build** or local dev build? (TestFlight/Local)
3. **How long ago did you upload** the build with the icon? (minutes/hours/days)
4. **Is the build still processing** in TestFlight? (Yes/No/Don't know)

## Based on Your Answers

### If icon shows in App Store Connect + TestFlight build + processing complete:
- **Likely**: Backend propagation delay (wait 24-48 hours)
- **OR**: StoreKit configuration issue (check scheme settings)

### If icon does NOT show in App Store Connect:
- **Likely**: Build doesn't include valid icon
- **Fix**: Create fresh archive, verify Assets.car exists, upload again

### If testing with local dev build:
- **Expected**: StoreKit won't show icon (uses App Store metadata)
- **Fix**: Test with TestFlight build instead

### If StoreKit config is in scheme:
- **Fix**: Remove it before archiving (Edit Scheme → Run → Options → StoreKit Configuration → None)
