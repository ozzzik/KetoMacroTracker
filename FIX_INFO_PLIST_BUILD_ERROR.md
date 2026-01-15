# Fix Info.plist Build Error

## The Error
```
Multiple commands produce '.../KetoMacroTracker.app/Info.plist'
The Copy Bundle Resources build phase contains this target's Info.plist file
```

## The Problem
The `Info.plist` file is being:
1. Processed as the app's Info.plist (via `INFOPLIST_FILE` setting) ✅
2. Copied as a resource file (in Copy Bundle Resources) ❌

This creates a conflict because Xcode tries to create the same file twice.

## Solution: Remove Info.plist from Copy Bundle Resources

### Step 1: Open Xcode
1. Open `KetoMacroTracker.xcodeproj` in Xcode

### Step 2: Select the Target
1. Click on the project name in the Project Navigator (left sidebar)
2. Select the **KetoMacroTracker** target (not the project)

### Step 3: Go to Build Phases
1. Click on the **"Build Phases"** tab at the top
2. Expand **"Copy Bundle Resources"**

### Step 4: Remove Info.plist
1. Look for `Info.plist` in the list
2. Select it
3. Press **Delete** or click the **"-"** button
4. Confirm removal if prompted

### Step 5: Clean and Rebuild
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Product → Build** (Cmd+B)

## Why This Happens

When you create a manual `Info.plist` file and set `INFOPLIST_FILE` in build settings, Xcode processes it as the app's Info.plist. However, if the file is also in the "Copy Bundle Resources" build phase, Xcode tries to copy it as a regular resource file, causing a conflict.

The `Info.plist` should **only** be processed via `INFOPLIST_FILE`, not copied as a resource.

## Verification

After removing it from Copy Bundle Resources:
- ✅ Build should succeed
- ✅ Info.plist will be processed correctly
- ✅ Icon configuration will be included
- ✅ StoreKit should be able to read the icon

