# App Store Connect - Subscription Setup Guide

Complete guide for setting up subscriptions in App Store Connect before uploading to the App Store.

## Prerequisites

1. **App Store Connect Account** with Admin or App Manager role
2. **App created** in App Store Connect (or ready to create)
3. **Bundle ID** matches your app: `com.ketomacrotracker` (or your actual bundle ID)
4. **Agreements, Tax, and Banking** completed in App Store Connect

## Subscription Products to Create

You need to create **2 subscription products**:

### Product 1: Monthly Subscription
- **Product ID**: `com.ketomacrotracker.monthly`
- **Type**: Auto-Renewable Subscription
- **Subscription Duration**: 1 Month
- **Price**: $0.99 USD

### Product 2: Yearly Subscription
- **Product ID**: `com.ketomacrotracker.yearly`
- **Type**: Auto-Renewable Subscription
- **Subscription Duration**: 1 Year
- **Price**: $7.99 USD

## Step-by-Step Setup Instructions

### Step 1: Create Subscription Group

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to **Features** → **In-App Purchases**
4. Click **"+"** button → Select **"Create Subscription Group"**
5. **Group Name**: `Premium Subscription`
6. Click **"Create"**

### Step 2: Create Monthly Subscription

1. In the subscription group, click **"+"** → **"Create Subscription"**
2. **Subscription Information**:
   - **Reference Name**: `Monthly Premium`
   - **Product ID**: `com.ketomacrotracker.monthly`
   - **Subscription Duration**: `1 Month`
   - Click **"Create"**

3. **Subscription Details**:
   - **Display Name**: `Keto Macro Tracker Premium - Monthly`
   - **Description**: 
     ```
     Monthly premium subscription for Keto Macro Tracker. Unlock unlimited food logging, advanced analytics, barcode scanning, and more.
     ```

4. **Pricing and Availability**:
   - Click **"Add Subscription Pricing"**
   - Select **Base Territory** (usually United States)
   - Set price: **$4.99** (or your chosen price)
   - Click **"Next"** → Review → **"Add"**

5. **Localization** (Required for at least one language):
   - Click **"+"** under Localizations
   - **Language**: English (U.S.)
   - **Display Name**: `Keto Macro Tracker Premium - Monthly`
   - **Description**: 
     ```
     Monthly premium subscription for Keto Macro Tracker. Unlock unlimited food logging, advanced analytics, barcode scanning, and more.
     ```
   - Click **"Save"**

6. **Review Information**:
   - **Review Notes** (optional): 
     ```
     This is a monthly subscription that unlocks premium features including unlimited food logging, advanced analytics, barcode scanning, HealthKit integration, and more.
     ```
   - **Screenshot** (optional): Upload a screenshot of the subscription screen

7. Click **"Save"** at the top right

### Step 3: Create Yearly Subscription

1. In the same subscription group, click **"+"** → **"Create Subscription"**
2. **Subscription Information**:
   - **Reference Name**: `Yearly Premium`
   - **Product ID**: `com.ketomacrotracker.yearly`
   - **Subscription Duration**: `1 Year`
   - Click **"Create"**

3. **Subscription Details**:
   - **Display Name**: `Keto Macro Tracker Premium - Yearly`
   - **Description**: 
     ```
     Yearly premium subscription for Keto Macro Tracker. Best value! Unlock unlimited food logging, advanced analytics, barcode scanning, and more.
     ```

4. **Pricing and Availability**:
   - Click **"Add Subscription Pricing"**
   - Select **Base Territory** (usually United States)
   - Set price: **$7.99** (or your chosen price)
   - Click **"Next"** → Review → **"Add"**

5. **Localization**:
   - Click **"+"** under Localizations
   - **Language**: English (U.S.)
   - **Display Name**: `Keto Macro Tracker Premium - Yearly`
   - **Description**: 
     ```
     Yearly premium subscription for Keto Macro Tracker. Best value! Unlock unlimited food logging, advanced analytics, barcode scanning, and more.
     ```
   - Click **"Save"**

6. **Review Information**:
   - **Review Notes** (optional): 
     ```
     This is a yearly subscription that unlocks premium features including unlimited food logging, advanced analytics, barcode scanning, HealthKit integration, and more. Best value compared to monthly subscription.
     ```

7. Click **"Save"** at the top right

### Step 4: Configure Subscription Group Display Order

1. In the subscription group, you'll see both subscriptions
2. **Drag to reorder** if needed (yearly should be first to show "Best Value")
3. The order here affects how they appear in your app

### Step 5: Submit for Review

1. Both subscriptions should show status: **"Ready to Submit"**
2. You can submit them along with your app, or separately
3. Apple will review subscriptions as part of app review

## Important Notes

### Product IDs Must Match Exactly
- ✅ `com.ketomacrotracker.monthly`
- ✅ `com.ketomacrotracker.yearly`

These must **exactly match** what's in your code (`SubscriptionManager.swift`).

### Pricing Considerations

**Current Configuration**:
- Monthly: $0.99/month
- Yearly: $7.99/year (equivalent to $0.67/month)

**Savings**: ~33% discount for yearly subscription

You can adjust prices, but make sure:
- Yearly is cheaper than 12x monthly (to show value)
- Prices are competitive with similar apps
- Consider regional pricing (App Store Connect can auto-calculate)

### Subscription Features to Mention

Make sure your descriptions mention:
- ✅ Unlimited food logging
- ✅ Advanced analytics
- ✅ Barcode scanning
- ✅ HealthKit integration
- ✅ Data export
- ✅ Extended history
- ✅ Unlimited custom meals

### Testing Before Submission

1. **Remove StoreKit Configuration** from Xcode scheme:
   - Product → Scheme → Edit Scheme → Run → Options
   - Set StoreKit Configuration to **"None"**

2. **Test with Sandbox Account**:
   - Create sandbox tester in App Store Connect
   - Sign out of regular Apple ID in Settings → App Store
   - Test purchases will use sandbox account

3. **Verify Product IDs**:
   - Make sure products load correctly
   - Test purchase flow
   - Test restore purchases

## Checklist Before Uploading

- [ ] Both subscription products created in App Store Connect
- [ ] Product IDs match exactly: `com.ketomacrotracker.monthly` and `com.ketomacrotracker.yearly`
- [ ] Subscription group created: "Premium Subscription"
- [ ] Both products added to the same subscription group
- [ ] Pricing set for both products
- [ ] At least one localization added (English)
- [ ] Review information completed
- [ ] StoreKit configuration removed from Xcode scheme (for production)
- [ ] Tested with sandbox account
- [ ] App Store Connect agreements completed
- [ ] Tax and banking information completed

## After Submission

1. **App Review**: Apple will review your subscriptions along with your app
2. **Testing**: Test purchases work in TestFlight
3. **Production**: Once approved, subscriptions work for all users
4. **Monitoring**: Monitor subscription metrics in App Store Connect

## Support Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

## Troubleshooting

### Products Don't Load
- Verify product IDs match exactly
- Check that subscriptions are "Ready to Submit" or "Approved"
- Ensure app bundle ID matches App Store Connect app
- Remove StoreKit configuration file from scheme

### Purchase Fails
- Use sandbox tester account
- Check agreements are completed
- Verify tax/banking information

### Subscription Not Showing
- Check subscription group is set up correctly
- Verify both products are in the same group
- Ensure app is using correct product IDs

---

**Important**: Keep your StoreKit configuration file (`Configuration.storekit`) for local testing, but make sure it's **NOT** selected in the scheme when building for App Store submission.

