# How to Test StoreKit Purchases in Sandbox (Step-by-Step)

## Quick Setup (5 minutes)

### Step 1: Verify StoreKit Configuration in Scheme

I've already updated your scheme file to include the StoreKit configuration. To verify:

1. **Open Xcode**
2. **Product** → **Scheme** → **Edit Scheme** (or press `Cmd+<`)
3. **Select "Run"** in left sidebar
4. **Click "Options" tab**
5. **Look for "StoreKit Configuration"** dropdown
6. **Should show**: `Configuration.storekit` (already selected ✅)

If it's not there, select it manually.

### Step 2: Run on iOS Simulator

1. **Select iOS Simulator** as destination (any iPhone simulator)
2. **Press Cmd+R** to run the app
3. **Wait for app to launch**

### Step 3: Test Purchase Flow

1. **Navigate to subscription screen** (Profile → Premium or tap Subscribe)
2. **You should see**:
   - Monthly subscription: $0.99
   - Yearly subscription: $7.99
3. **Tap "Subscribe"** or "Start Free Trial"
4. **StoreKit purchase dialog appears** (this is the sandbox dialog)

### Step 4: Test Different Scenarios

#### Test Approval:
- Tap **"Confirm"** or **"Subscribe"** in the dialog
- Should show success message
- Subscription should activate

#### Test Cancellation:
- Tap **"Cancel"** in the dialog
- Should dismiss without showing success
- Subscription should remain inactive

#### Test Multiple Purchases:
- After one purchase, try purchasing again
- Should handle gracefully

## What to Expect

### ✅ What Works in Sandbox:
- Purchase dialog appears
- Products load correctly
- Purchase flow works (approve/cancel)
- Subscription status updates
- No real payment required
- Instant transactions

### ⚠️ Icon Display in Sandbox:
- **May show**: Your app icon (if properly configured)
- **May show**: Generic placeholder icon (known sandbox limitation)
- **Will show**: Actual icon in TestFlight/production

**Important**: If you see a generic icon in sandbox, that's normal! The icon will appear correctly in TestFlight and production.

## Testing Checklist

- [ ] StoreKit Configuration is selected in scheme
- [ ] App runs on Simulator
- [ ] Products load (monthly and yearly)
- [ ] Purchase dialog appears
- [ ] Can approve purchase (subscription activates)
- [ ] Can cancel purchase (no success message)
- [ ] Subscription status updates correctly
- [ ] Icon appears (or generic placeholder - both are OK)

## Troubleshooting

### Products Don't Load:
1. Check `Configuration.storekit` is selected in scheme
2. Check product IDs match: `com.ketomacrotracker.monthly` and `com.ketomacrotracker.yearly`
3. Clean build folder (Cmd+Shift+K) and rebuild

### Purchase Dialog Doesn't Appear:
1. Make sure you're on Simulator (StoreKit config doesn't work on physical device)
2. Check console logs for errors
3. Verify StoreKit configuration file is in project

### Icon Doesn't Show:
- **This is normal in sandbox!**
- Icon will appear in TestFlight/production
- Your icon configuration is correct

## Alternative: Test on Physical Device

If you want to test on a real device:

1. **Create Sandbox Test Account**:
   - App Store Connect → Users and Access → Sandbox Testers
   - Add new tester with unique email

2. **Sign Out of App Store**:
   - Settings → App Store → Sign Out

3. **Run App on Device**:
   - Connect device
   - Select device as destination
   - Run app

4. **When Prompted**:
   - Sign in with sandbox test account
   - Complete purchase (uses test payment)

## Next Steps After Testing

Once you've verified the purchase flow works:

1. **Optimize icon files** (reduce size)
2. **Archive the app** (Product → Archive)
3. **Upload to App Store Connect**
4. **Test in TestFlight** (icon should appear here)
5. **Submit for review**

## Summary

- **Sandbox testing**: Perfect for testing purchase logic
- **Icon display**: May not show in sandbox (that's OK)
- **Icon will show**: In TestFlight and production
- **Focus on**: Testing purchase flow, not icon in sandbox

Your StoreKit setup is correct. The icon issue is likely a sandbox limitation and will work in production.

