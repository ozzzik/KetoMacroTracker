# SF Symbols Guide for Keto Macro Tracker

## 🎯 **Recommended SF Symbols for Your App**

### **Food & Nutrition Icons**
- `fork.knife` - General food/eating
- `applelogo` - Healthy food
- `leaf.fill` - Vegetables/greens
- `fish.fill` - Protein sources
- `drop.fill` - Water/hydration
- `scalemass.fill` - Weight tracking
- `heart.fill` - Health/heart
- `flame.fill` - Calories/burning
- `bolt.fill` - Energy

### **Navigation Icons**
- `calendar` - Today/Date
- `chart.line.uptrend.xyaxis` - History/Charts
- `magnifyingglass` - Search
- `person.circle` - Profile
- `plus` - Add/Create
- `minus` - Remove/Delete
- `pencil` - Edit
- `checkmark` - Complete/Done
- `xmark` - Cancel/Close

### **Macro Icons**
- `circle.fill` - Protein (Red)
- `triangle.fill` - Carbs (Blue)
- `diamond.fill` - Fat (Yellow)
- `square.fill` - Calories (Purple)

### **Actions & States**
- `square.and.arrow.up` - Share
- `gear` - Settings
- `questionmark.circle` - Help
- `info.circle` - Information
- `exclamationmark.triangle` - Warning
- `checkmark.circle.fill` - Success
- `xmark.circle.fill` - Error

### **Time & Progress**
- `clock` - Time
- `timer` - Timer
- `stopwatch` - Stopwatch
- `chart.bar.fill` - Progress bars
- `chart.pie.fill` - Pie charts
- `chart.xyaxis.line` - Line charts

## 🎨 **How to Use SF Symbols in SwiftUI**

```swift
// Basic usage
Image(systemName: "fork.knife")

// With styling
Image(systemName: "heart.fill")
    .foregroundColor(.red)
    .font(.title)

// With custom size
Image(systemName: "plus")
    .font(.system(size: 24, weight: .bold))

// In buttons
Button(action: {}) {
    HStack {
        Image(systemName: "plus")
        Text("Add Food")
    }
}
```

## 📱 **Download SF Symbols App**
- Download from the Mac App Store
- Browse all 3,000+ symbols
- Export as PDF or PNG
- Use in your designs

## 🎯 **Color Coding for Macros**
- **Protein**: Red (`#FF6B6B` or `Color.red`)
- **Carbs**: Blue (`#4ECDC4` or `Color.blue`)
- **Fat**: Yellow (`#FFE66D` or `Color.yellow`)
- **Calories**: Purple (`#A8E6CF` or `Color.purple`)


