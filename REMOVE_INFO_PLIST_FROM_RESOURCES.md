# Remove Info.plist from Copy Bundle Resources

## The Problem
`Info.plist` is being both:
1. Processed as the app's Info.plist (via `INFOPLIST_FILE` setting) ✅
2. Copied as a resource file (in Copy Bundle Resources) ❌

This creates a conflict.

## Solution: Remove from Copy Bundle Resources

### Step-by-Step Instructions:

1. **Open Xcode**
   - Open `KetoMacroTracker.xcodeproj`

2. **Select the Target**
   - Click on the **project name** (blue icon) in the Project Navigator (left sidebar)
   - Select the **KetoMacroTracker** target (under "TARGETS", not "PROJECT")

3. **Go to Build Phases**
   - Click on the **"Build Phases"** tab at the top

4. **Find Copy Bundle Resources**
   - Scroll down to find **"Copy Bundle Resources"**
   - Click the triangle to expand it

5. **Remove Info.plist**
   - Look for `Info.plist` in the list
   - **Select it** (click on it)
   - Press the **Delete** key on your keyboard
   - OR click the **"-"** button at the bottom of the list
   - Confirm if prompted

6. **Verify It's Gone**
   - `Info.plist` should no longer appear in the "Copy Bundle Resources" list
   - It should still be visible in the Project Navigator (that's fine)

7. **Clean and Build**
   - **Product → Clean Build Folder** (Cmd+Shift+K)
   - **Product → Build** (Cmd+B)

## Why This Works

- `Info.plist` should only be processed via `INFOPLIST_FILE` setting
- It should NOT be copied as a resource file
- Removing it from Copy Bundle Resources fixes the conflict

## If You Can't Find It

If `Info.plist` doesn't appear in Copy Bundle Resources but you still get the error:

1. Try **Product → Clean Build Folder** first
2. Close Xcode completely
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/KetoMacroTracker-*
   ```
4. Reopen Xcode and try building again

