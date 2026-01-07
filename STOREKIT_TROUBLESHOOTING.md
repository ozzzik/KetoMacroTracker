# StoreKit Configuration Troubleshooting

## Current Issue
Products are not loading (0 products found). The logs show:
```
📦 Raw products loaded: 0
✅ Loaded 0 products
```

## What I Fixed
1. Updated the scheme file to use the correct container path: `container:KetoMacroTracker/Configuration.storekit`

## Steps to Verify in Xcode

### 1. Check StoreKit Configuration in Scheme
1. Open Xcode
2. Go to **Product → Scheme → Edit Scheme...** (or press `Cmd + <`)
3. Select **Run** in the left sidebar
4. Go to the **Options** tab
5. Under **StoreKit Configuration**, you should see:
   - `KetoMacroTracker/Configuration.storekit` selected
   - If it's not there, click the dropdown and select it
   - If it's not in the dropdown, click the "+" button and browse to `KetoMacroTracker/Configuration.storekit`

### 2. Verify Configuration File
The file should be at: `KetoMacroTracker/Configuration.storekit`

It should contain:
- Product ID: `com.ketomacrotracker.monthly`
- Product ID: `com.ketomacrotracker.yearly`

### 3. Clean and Rebuild
1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. **Product → Build** (Cmd+B)
3. Stop the app if it's running
4. Run the app again (Cmd+R)

### 4. Check Console Logs
After running, you should see:
```
📦 Loading products...
📦 Product IDs to load: ["com.ketomacrotracker.monthly", "com.ketomacrotracker.yearly"]
📦 Raw products loaded: 2  ← Should be 2, not 0!
✅ Loaded 2 products
  - Keto Macro Tracker Premium - Monthly (com.ketomacrotracker.monthly): $4.99
  - Keto Macro Tracker Premium - Yearly (com.ketomacrotracker.yearly): $49.99
```

## Common Issues

### Issue 1: StoreKit Configuration Not Selected
**Symptom**: Products don't load
**Solution**: Make sure the StoreKit configuration is selected in the scheme Options tab

### Issue 2: Wrong File Path
**Symptom**: Products don't load
**Solution**: The path should be `container:KetoMacroTracker/Configuration.storekit` or just `KetoMacroTracker/Configuration.storekit` in the scheme

### Issue 3: Configuration File Not in Project
**Symptom**: File doesn't appear in dropdown
**Solution**: 
1. Right-click on `KetoMacroTracker` folder in Xcode
2. Select "Add Files to KetoMacroTracker..."
3. Select `Configuration.storekit`
4. Make sure "Copy items if needed" is checked
5. Click "Add"

### Issue 4: Running on Device Instead of Simulator
**Symptom**: Products don't load on device
**Solution**: StoreKit configuration files work best in the simulator. For device testing, you need App Store Connect setup.

### Issue 5: Multiple Configuration Files
**Symptom**: Confusion about which file to use
**Solution**: There should only be ONE `Configuration.storekit` file at `KetoMacroTracker/Configuration.storekit`

## Testing Without StoreKit Configuration

If StoreKit configuration still doesn't work, you can use the debug button:
1. Go to Profile → Premium
2. Use the "Activate Premium (Debug)" button (only visible in DEBUG builds)
3. This simulates premium activation for testing

## Next Steps

1. **Verify the scheme configuration** in Xcode (most important!)
2. **Clean and rebuild** the project
3. **Run on simulator** (not device) for best results
4. **Check console logs** for product loading messages
5. If still not working, **verify the file is in the Xcode project** (visible in Project Navigator)

## Still Not Working?

If products still don't load after following these steps:
1. Check if you're running on a simulator (recommended for StoreKit testing)
2. Verify the Configuration.storekit file is valid JSON (no syntax errors)
3. Make sure the product IDs exactly match: `com.ketomacrotracker.monthly` and `com.ketomacrotracker.yearly`
4. Try removing and re-adding the StoreKit configuration in the scheme
5. Restart Xcode

