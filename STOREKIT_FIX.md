# StoreKit Configuration Fix Guide

## Issue
Products are not loading (0 products) even though StoreKit configuration is set up.

## Fixes Applied

1. **Moved File**: Moved `Configuration.storekit` from project root to `KetoMacroTracker/Configuration.storekit`
2. **Fixed Scheme Path**: Updated to `container:KetoMacroTracker/Configuration.storekit`
3. **Added StoreKit Version**: Added `"_storeKitVersion" : "3.0"` to settings

## Additional Steps to Fix

### Step 1: Verify File Location
The `Configuration.storekit` file should be in the KetoMacroTracker folder:
```
/Users/ohardoon/KetoMacroTracker/KetoMacroTracker/Configuration.storekit
```
✅ **Already done!** The file has been moved to the correct location.

### Step 2: Ensure File is in Xcode Project
1. Open Xcode
2. In the Project Navigator, verify `Configuration.storekit` appears
3. If it doesn't appear:
   - Right-click on project root
   - Select "Add Files to KetoMacroTracker..."
   - Select `Configuration.storekit`
   - Make sure "Copy items if needed" is **UNCHECKED**
   - Click "Add"

### Step 3: Verify Scheme Configuration
1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme...**
2. Select **Run** in left sidebar
3. Go to **Options** tab
4. Under **StoreKit Configuration**, it should show `Configuration.storekit`
5. If it shows "None" or wrong file:
   - Click the dropdown
   - Select `Configuration.storekit`
   - Click **Close**

### Step 4: Update Xcode Project Reference
1. In Xcode, check if `Configuration.storekit` appears in the Project Navigator under `KetoMacroTracker` folder
2. If it doesn't appear:
   - Right-click on `KetoMacroTracker` folder in Project Navigator
   - Select "Add Files to KetoMacroTracker..."
   - Navigate to and select `KetoMacroTracker/Configuration.storekit`
   - Make sure "Copy items if needed" is **UNCHECKED**
   - Click "Add"

### Step 5: Clean Build
1. In Xcode: **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. Quit Xcode completely
3. Reopen Xcode
4. Build and run again

### Step 6: Verify Products Load
When you run the app, check console logs. You should see:
```
📦 Loading products...
✅ Loaded 2 products
  - Keto Macro Tracker Premium - Monthly (com.ketomacrotracker.monthly): $4.99
  - Keto Macro Tracker Premium - Yearly (com.ketomacrotracker.yearly): $49.99
```

## If Still Not Working

### Verify Scheme Configuration
1. In Xcode: **Product** → **Scheme** → **Edit Scheme...**
2. Select **Run** → **Options** tab
3. Under **StoreKit Configuration**, verify it shows: `KetoMacroTracker/Configuration.storekit`
4. If it shows something else, select the correct file from the dropdown

### Debug Mode
For immediate testing, use the debug button:
- Go to **Profile** → Tap **"Activate Premium (Debug)"**
- This activates premium without StoreKit (DEBUG builds only)

## Product IDs
- Monthly: `com.ketomacrotracker.monthly`
- Yearly: `com.ketomacrotracker.yearly`

These must match exactly in both the StoreKit file and your code.

