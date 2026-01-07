# StoreKit Configuration Setup Guide

## Overview
This guide explains how to set up StoreKit for testing subscriptions locally in Xcode.

## Steps to Enable StoreKit Testing

### 1. Add StoreKit Configuration File to Xcode Project

1. Open your project in Xcode
2. Right-click on the project root in the navigator
3. Select "Add Files to [Project Name]..."
4. Navigate to and select `Configuration.storekit`
5. Make sure "Copy items if needed" is **unchecked** (file should be referenced, not copied)
6. Click "Add"

### 2. Configure Scheme to Use StoreKit Configuration

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme...**
2. Select **Run** in the left sidebar
3. Go to the **Options** tab
4. Under **StoreKit Configuration**, select `Configuration.storekit`
5. Click **Close**

### 3. Test Subscriptions

Now when you run the app in the simulator or on a device:
- Products will load from the StoreKit configuration file
- Purchases will be simulated (no real charges)
- You can test subscription flows without App Store Connect setup

## Product IDs

The current product IDs configured are:
- `com.ketomacrotracker.monthly` - Monthly subscription ($4.99)
- `com.ketomacrotracker.yearly` - Yearly subscription ($49.99)

## For Production (App Store Connect)

When you're ready to test with real products:

1. **Create Products in App Store Connect:**
   - Go to App Store Connect → Your App → In-App Purchases
   - Create subscription products with the exact IDs:
     - `com.ketomacrotracker.monthly`
     - `com.ketomacrotracker.yearly`
   - Set up subscription groups and pricing

2. **Remove StoreKit Configuration:**
   - In Xcode scheme settings, set StoreKit Configuration to "None"
   - The app will now use real products from App Store Connect

3. **Test with Sandbox Account:**
   - Use a sandbox tester account in App Store Connect
   - Sign out of your regular Apple ID in Settings → App Store
   - When prompted during purchase, use sandbox credentials

## Troubleshooting

### Products Not Loading
- Check that `Configuration.storekit` is added to the project
- Verify the scheme is configured to use the StoreKit file
- Check console logs for product loading errors
- Ensure product IDs match exactly (case-sensitive)

### Purchases Not Working
- Verify you're using a simulator or device (not just preview)
- Check that the StoreKit configuration is selected in scheme
- Look for error messages in console logs
- Try restarting Xcode and cleaning build folder (Cmd+Shift+K)

### Subscription Status Not Updating
- Check console logs for transaction updates
- Verify `updateSubscriptionStatus()` is being called
- Ensure transaction listener is running (check init logs)

## Debug Logging

The SubscriptionManager includes detailed logging. Look for:
- `📦 Loading products...` - Product loading
- `💳 Starting purchase...` - Purchase initiation
- `✅ Transaction verified...` - Successful purchase
- `❌ Purchase failed...` - Error details

Enable console logging in Xcode to see these messages.



