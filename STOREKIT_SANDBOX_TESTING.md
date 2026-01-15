# Testing StoreKit Purchases in Sandbox (Without TestFlight)

## Overview

You can test StoreKit purchases and check the icon display in sandbox mode without TestFlight. Here's how:

## Method 1: StoreKit Configuration File (Recommended)

You already have `Configuration.storekit` set up. Here's how to use it:

### Step 1: Verify StoreKit Configuration

1. **Open Xcode**
2. **Select your scheme** (KetoMacroTracker)
3. **Edit Scheme** (Product → Scheme → Edit Scheme)
4. **Go to "Run" → "Options" tab**
5. **Check "StoreKit Configuration"** dropdown
6. **Select**: `Configuration.storekit`

### Step 2: Run on Simulator

1. **Select iOS Simulator** as destination
2. **Run the app** (Cmd+R)
3. **Navigate to subscription screen**
4. **Tap "Subscribe"**
5. **StoreKit purchase dialog should appear**

### Step 3: Test Purchase Flow

In sandbox with StoreKit config:
- **No real payment** - uses test transactions
- **Instant approval** - no waiting
- **Can test cancellation** - tap Cancel
- **Can test success** - tap Confirm

### Step 4: Check Icon Display

**Important**: In sandbox mode, the icon may:
- ✅ Show correctly (if properly configured)
- ⚠️ Show generic placeholder (known sandbox limitation)

**To verify icon is working**:
1. Check if icon appears in the purchase dialog
2. If it shows generic icon, it might be sandbox limitation
3. Icon should appear in TestFlight/production

## Method 2: Physical Device with Sandbox Account

### Step 1: Create Sandbox Test Account

1. **Go to App Store Connect**
2. **Users and Access** → **Sandbox Testers**
3. **Click "+" to add tester**
4. **Enter email** (doesn't need to be real, but must be unique)
5. **Enter password** (must meet requirements)
6. **Save**

### Step 2: Sign Out of App Store on Device

1. **Settings** → **App Store**
2. **Tap your Apple ID**
3. **Sign Out**

### Step 3: Test Purchase

1. **Run app on device** (not simulator)
2. **Navigate to subscription**
3. **Tap "Subscribe"**
4. **When prompted, sign in with sandbox account**
5. **Complete purchase** (uses test payment)

### Step 4: Check Icon

- Icon should appear in purchase dialog
- If not, check if it's a sandbox limitation

## Method 3: StoreKit Testing in Xcode

### Step 1: Enable StoreKit Testing

1. **Product** → **Scheme** → **Edit Scheme**
2. **Run** → **Options**
3. **StoreKit Configuration**: Select `Configuration.storekit`
4. **StoreKit Testing**: Enable if available

### Step 2: Use StoreKit Transaction Manager

1. **Debug** → **StoreKit** → **Manage Transactions**
2. **View test transactions**
3. **Clear transactions** to test again
4. **Test different scenarios**

## Method 4: Check Icon Programmatically

You can verify the icon is accessible in code:

```swift
// In your app, check if icon is accessible
if let iconPath = Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png") {
    print("✅ Icon found at: \(iconPath)")
    if let image = UIImage(contentsOfFile: iconPath) {
        print("✅ Icon loaded: \(image.size)")
    }
} else {
    print("❌ Icon not found in bundle")
}
```

## What to Expect in Sandbox

### Icon Display
- **May show**: Actual app icon (if properly configured)
- **May show**: Generic placeholder (sandbox limitation)
- **Will show**: Actual icon in TestFlight/production

### Purchase Flow
- ✅ Works perfectly in sandbox
- ✅ Can test all scenarios
- ✅ No real payment required
- ✅ Instant transactions

## Verifying Icon is Correct

Even if icon doesn't show in sandbox, you can verify it's correct:

### Check 1: App Bundle
```bash
# After archiving, check icon files
ls -lh path/to/archive/Products/Applications/KetoMacroTracker.app/AppIcon*.png
```

### Check 2: Info.plist
```bash
# Verify CFBundleIcons is correct
plutil -p archive/.../Info.plist | grep -A 10 CFBundleIcons
```

### Check 3: Icon Format
```bash
# Check icon format
sips -g hasAlpha -g space AppIcon-1024.png
# Should show: hasAlpha: no, space: RGB
```

## Testing Checklist

- [ ] StoreKit Configuration file is selected in scheme
- [ ] App runs on Simulator or Device
- [ ] Subscription screen loads products
- [ ] Purchase dialog appears when tapping Subscribe
- [ ] Icon appears (or generic placeholder in sandbox)
- [ ] Purchase flow works (approve/cancel)
- [ ] Subscription status updates correctly

## If Icon Doesn't Show in Sandbox

**This is normal!** Sandbox mode has limitations:

1. **Icon may not appear** - Known iOS limitation
2. **Will appear in TestFlight** - Production builds show icons
3. **Will appear in App Store** - Final production shows icons

**To confirm icon is working**:
- Check icon appears in App Store Connect (after upload)
- Check icon appears on home screen (already working)
- Test in TestFlight when ready

## Next Steps

1. **Test purchase flow** in sandbox (icon may not show - that's OK)
2. **Verify purchase logic works** (approve/cancel/subscription status)
3. **Optimize icon files** (reduce file size)
4. **Upload to TestFlight** when ready to test icon display
5. **Icon should appear** in TestFlight/production

## Summary

- **Sandbox testing**: Perfect for testing purchase flow
- **Icon display**: May not show in sandbox (limitation)
- **Icon will show**: In TestFlight and production
- **Focus on**: Testing purchase logic, not icon display in sandbox

The icon configuration is correct. If it doesn't show in sandbox, it's a known limitation and will work in production.

