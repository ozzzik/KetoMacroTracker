# Complete StoreKit Configuration Checklist

## ✅ Verification Checklist

### 1. File Location
- [x] File exists at: `KetoMacroTracker/Configuration.storekit`
- [x] File is valid JSON
- [x] Product IDs match: `com.ketomacrotracker.monthly` and `com.ketomacrotracker.yearly`

### 2. Xcode Project Setup
**CRITICAL**: The file must be in the Xcode project, not just in the filesystem!

1. Open Xcode
2. In the **Project Navigator** (left sidebar), look for `Configuration.storekit`
3. It should appear under the `KetoMacroTracker` folder
4. **If it's NOT visible**:
   - Right-click on `KetoMacroTracker` folder in Project Navigator
   - Select **"Add Files to KetoMacroTracker..."**
   - Navigate to and select `KetoMacroTracker/Configuration.storekit`
   - **IMPORTANT**: Make sure "Copy items if needed" is **UNCHECKED**
   - Make sure "Add to targets: KetoMacroTracker" is **CHECKED**
   - Click **"Add"**

### 3. Scheme Configuration
1. In Xcode: **Product → Scheme → Edit Scheme...** (or `Cmd + <`)
2. Select **Run** in left sidebar
3. Go to **Options** tab
4. Under **StoreKit Configuration**:
   - Should show: `KetoMacroTracker/Configuration.storekit` or just `Configuration.storekit`
   - If it shows "None", click dropdown and select the file
   - If file is not in dropdown, it means it's not in the Xcode project (see step 2)

### 4. Running Environment
**CRITICAL**: StoreKit configuration files ONLY work on Simulator!

- ✅ **Run on Simulator** (iPhone 15, iPhone 14, etc.)
- ❌ **Do NOT run on physical device** (StoreKit config won't work)

### 5. Clean Build
After making changes:
1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. **Quit Xcode completely** (Cmd+Q)
3. **Reopen Xcode**
4. **Product → Build** (Cmd+B)
5. **Product → Run** (Cmd+R) - **ON SIMULATOR**

### 6. Verify in Console
After running, check console logs. You should see:
```
📱 Running on Simulator - StoreKit config should work
📦 Raw products loaded: 2  ← Should be 2!
✅ Loaded 2 products
  - Keto Macro Tracker Premium - Monthly (com.ketomacrotracker.monthly): $4.99
  - Keto Macro Tracker Premium - Yearly (com.ketomacrotracker.yearly): $49.99
```

## Common Issues & Solutions

### Issue: "0 products loaded" even though config is selected

**Solution 1: File not in Xcode project**
- The file exists in filesystem but Xcode doesn't know about it
- Add it to project (see step 2 above)

**Solution 2: Running on device**
- StoreKit config only works on simulator
- Switch to simulator and run again

**Solution 3: Xcode cache**
- Clean build folder
- Quit and restart Xcode
- Build and run again

**Solution 4: Scheme not saved**
- Make sure you click "Close" after selecting StoreKit config
- Verify it's still selected after reopening scheme editor

### Issue: File doesn't appear in StoreKit Configuration dropdown

**Solution**: File is not in Xcode project
- Add it to project (see step 2 above)
- Make sure it appears in Project Navigator

### Issue: Products load but purchase doesn't work

**Solution**: This is normal in StoreKit testing
- Use the debug button: "Activate Premium (Debug)"
- Or test purchases in StoreKit testing environment

## Final Verification Steps

1. ✅ File is in Xcode Project Navigator
2. ✅ File is selected in Scheme → Run → Options → StoreKit Configuration
3. ✅ Running on Simulator (not device)
4. ✅ Clean build and restart Xcode
5. ✅ Check console logs for "📦 Raw products loaded: 2"

## If Still Not Working

1. **Double-check file is in Xcode project** (most common issue!)
2. **Verify you're on simulator** (not device)
3. **Try removing and re-adding** the StoreKit config in scheme
4. **Restart Xcode completely**
5. **Check for multiple Configuration.storekit files** (should only be one)

## Debug Mode

If StoreKit still doesn't work, you can use debug mode:
- Go to Profile → Premium
- Click "Activate Premium (Debug)" button
- This simulates premium activation for testing

