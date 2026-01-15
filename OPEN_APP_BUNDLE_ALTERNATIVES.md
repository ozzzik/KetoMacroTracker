# Alternative Ways to Open App Bundle

## Method 1: Right-Click → Show Package Contents

1. **Right-click** on `KetoMacroTracker` (the app bundle)
2. **Click "Show Package Contents"**
3. This will open the bundle contents
4. Look for `Assets.car`

## Method 2: Use Terminal

1. **Open Terminal**
2. **Navigate to the Applications folder** in your archive:
   - You can drag the `Applications` folder from Finder into Terminal
   - OR type: `cd ` (with a space) then drag the `Applications` folder
3. **Run this command**:
   ```bash
   ls -lh KetoMacroTracker.app/Assets.car
   ```
4. This will show the file size if it exists

## Method 3: Use Finder's Go Menu

1. **Click on `KetoMacroTracker`** (select it, don't double-click)
2. **Right-click** → **"Show Package Contents"**
3. OR press **Cmd+Down Arrow** while `KetoMacroTracker` is selected

## Method 4: Direct Terminal Command

If you know the path to your archive, you can run:

```bash
ls -lh "/path/to/your/archive.xcarchive/Products/Applications/KetoMacroTracker.app/Assets.car"
```

## Quick Check: Does Assets.car Exist?

**Easiest method - use Terminal:**

1. **Open Terminal**
2. **Drag the `Applications` folder** from Finder into Terminal
3. **Type**: `ls -lh KetoMacroTracker.app/ | grep Assets`
4. **Press Enter**

This will show if `Assets.car` exists and its size.
