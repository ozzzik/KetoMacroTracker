# Subscription Features Guide

## Premium Features

The following features require a premium subscription:

1. **Unlimited Food Logging**
   - Free: Limited to 20-30 entries per day
   - Premium: Unlimited daily entries

2. **Advanced Analytics & Insights**
   - Free: Basic daily totals
   - Premium: Trends, weekly/monthly summaries, predictive insights

3. **Export & Backup**
   - Free: Not available
   - Premium: Export data to JSON/CSV, create backups

4. **Barcode Scanning**
   - Free: Not available
   - Premium: Scan product barcodes to find nutrition info

5. **HealthKit Integration**
   - Free: Not available
   - Premium: Sync nutrition data with Apple Health

6. **Home Screen Widgets**
   - Free: Not available
   - Premium: Widgets to track macros at a glance

7. **Extended History**
   - Free: Last 7 days
   - Premium: Unlimited historical data

8. **Unlimited Custom Meals**
   - Free: Limited to 3-5 custom meals
   - Premium: Unlimited custom meal templates

## Implementation

### Checking Premium Status

```swift
@EnvironmentObject var subscriptionManager: SubscriptionManager

if subscriptionManager.isPremiumActive {
    // Show premium feature
} else {
    // Show paywall or limit feature
}
```

### Adding Premium Gates

Example: Limiting custom meals

```swift
let maxFreeMeals = 5
if customMeals.count >= maxFreeMeals && !subscriptionManager.isPremiumActive {
    // Show paywall
    showingPaywall = true
} else {
    // Allow creating meal
}
```

### Product IDs

- Monthly: `com.ketomacrotracker.monthly`
- Yearly: `com.ketomacrotracker.yearly`

## Testing

In debug mode, you can simulate premium:
```swift
#if DEBUG
SubscriptionManager.shared.activateSubscription()
#endif
```




