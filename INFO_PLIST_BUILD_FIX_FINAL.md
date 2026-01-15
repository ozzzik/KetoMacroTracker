# Info.plist Build Error - Final Fix Required

## The Problem
Even though `excludedPaths = ("Info.plist")` is set in the `PBXFileSystemSynchronizedRootGroup`, Xcode is still auto-discovering Info.plist and adding it to Copy Bundle Resources during the build, causing the "Multiple commands produce Info.plist" error.

## Root Cause
With `PBXFileSystemSynchronizedRootGroup`, Xcode automatically discovers all files in the directory. The `excludedPaths` setting should prevent Info.plist from being discovered, but it appears this exclusion might not be working correctly for resources, or Xcode may need additional configuration to respect the exclusion.

## Current Configuration
✅ `excludedPaths = ("Info.plist")` is set in `PBXFileSystemSynchronizedRootGroup`  
✅ `GENERATE_INFOPLIST_FILE = NO`  
✅ `INFOPLIST_FILE = KetoMacroTracker/Info.plist`  
✅ Build phases show empty `files = ()` arrays (correct structure)

## Solution: Manual Fix in Xcode Required

Since the automatic exclusion isn't working, you need to manually remove Info.plist from Copy Bundle Resources in Xcode:

### Step 1: Open Xcode
- Open `KetoMacroTracker.xcodeproj`

### Step 2: Select Target
- Click on the project name in Project Navigator (blue icon)
- Select **KetoMacroTracker** target (under "TARGETS", not "PROJECT")

### Step 3: Go to Build Phases
- Click the **"Build Phases"** tab at the top

### Step 4: Expand Copy Bundle Resources
- Find **"Copy Bundle Resources"** section
- Click the disclosure triangle to expand it

### Step 5: Remove Info.plist
- Look for `Info.plist` in the list
- **Select it** (click on it)
- Press **Delete** key on your keyboard
- OR click the **"-"** (minus) button at the bottom
- Confirm removal if prompted

**Important**: If Info.plist is NOT visible in the Copy Bundle Resources list, but you still get the error, it means Xcode is auto-discovering it during the build. In this case, continue to Step 6.

### Step 6: Force Re-synchronization
If Info.plist isn't visible but the error persists:

1. **Close Xcode completely** (Cmd+Q)

2. **Delete DerivedData** (run in Terminal):
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/KetoMacroTracker-*
   ```

3. **Reopen Xcode**

4. **Wait for indexing** to complete (watch the progress bar)

5. **Clean Build Folder**: Product → Clean Build Folder (Cmd+Shift+K)

6. **Build**: Product → Build (Cmd+B)

### Step 7: Verify Fix
After building successfully:
- ✅ Build should succeed
- ✅ Info.plist should only be processed via `INFOPLIST_FILE` setting
- ✅ Info.plist should NOT appear in Copy Bundle Resources

## Alternative Solution (If Manual Removal Doesn't Work)

If manually removing Info.plist from Copy Bundle Resources doesn't work or it keeps getting re-added:

1. **Temporarily move Info.plist** outside the `PBXFileSystemSynchronizedRootGroup`:
   - Move `KetoMacroTracker/Info.plist` to `KetoMacroTracker.xcodeproj/Info.plist`
   - Update `INFOPLIST_FILE` to `Info.plist` (without the path)
   - This removes it from auto-discovery

2. **Or convert to explicit file references**:
   - Remove `PBXFileSystemSynchronizedRootGroup` and use explicit `PBXGroup` instead
   - This gives full control over which files are included
   - But this is a major change and might break other things

## Why This Happens

With `PBXFileSystemSynchronizedRootGroup`:
- Files are automatically discovered at build time
- The `excludedPaths` setting should prevent discovery, but there may be a bug or limitation where it doesn't work for plist files that are used as Info.plist
- Xcode tries to be helpful by including all discovered plist files as resources, even if they're the Info.plist
- This causes a conflict because Info.plist is already being processed via the `INFOPLIST_FILE` build setting

## Verification Checklist

After following the steps above:
- [ ] Info.plist is removed from Copy Bundle Resources (if it was there)
- [ ] DerivedData has been cleaned
- [ ] Xcode has been restarted
- [ ] Build succeeds without "Multiple commands produce Info.plist" error
- [ ] Info.plist is still accessible via `INFOPLIST_FILE = KetoMacroTracker/Info.plist`
- [ ] App builds and runs correctly
