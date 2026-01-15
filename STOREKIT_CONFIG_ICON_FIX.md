# StoreKit Configuration File - Icon Fix

## The Root Cause ✅

**The StoreKit configuration file in the scheme is preventing the app icon from appearing in purchase dialogs!**

When a StoreKit configuration file is attached to the scheme, StoreKit UI uses the configuration's data rather than your real App Store metadata, which means **no app icon appears** in subscription sheets.

## Solution Applied

I've removed the `storeKitConfigurationFileReference` from the LaunchAction in the scheme file.

### What Changed:
- **Before**: Scheme had `storeKitConfigurationFileReference = "container:KetoMacroTracker/Configuration.storekit"`
- **After**: Removed the StoreKit config reference from the scheme

## Important Notes

### For Local Development/Testing:
- **StoreKit config is still available** in the project (`Configuration.storekit`)
- You can manually enable it when needed:
  - **Product → Scheme → Edit Scheme**
  - **Run → Options**
  - **StoreKit Configuration**: Select `Configuration.storekit` when testing locally
  - **Remove it** before archiving for TestFlight/production

### For TestFlight/Production:
- **StoreKit config should NOT be in the scheme** when archiving
- The icon will now appear correctly in TestFlight and production
- StoreKit will use real App Store metadata instead of the config file

## Verification Steps

1. **Clean Build**: Product → Clean Build Folder (Cmd+Shift+K)
2. **Archive**: Product → Archive (this will use Release config without StoreKit file)
3. **Upload to TestFlight**
4. **Test Purchase Flow**: Icon should now appear in the subscription purchase dialog

## Why This Works

- **With StoreKit config**: StoreKit uses local config data (no icon metadata)
- **Without StoreKit config**: StoreKit uses real App Store metadata (includes icon)
- **TestFlight/Production**: Always uses App Store metadata, so icon appears

## If You Need StoreKit Config for Local Testing

You can temporarily add it back:
1. **Product → Scheme → Edit Scheme**
2. **Run → Options → StoreKit Configuration**
3. Select `Configuration.storekit`
4. **Remember to remove it before archiving!**

The icon should now appear in TestFlight and production builds! 🎉

