# Widget Setup Guide

The widget code has been created, but widgets require a separate Widget Extension target in Xcode.

## Setup Steps

1. **Create Widget Extension Target:**
   - In Xcode: File > New > Target
   - Select "Widget Extension"
   - Name it "KetoMacroWidgetExtension"
   - Uncheck "Include Configuration Intent" (we're using static configuration)

2. **Move Widget Files:**
   - Move `KetoMacroWidget.swift` to the widget extension target
   - Move `KetoMacroWidgetBundle.swift` to the widget extension target
   - In the widget bundle file, uncomment `@main` and remove `@main` from `KetoMacroTrackerApp.swift` in the widget target

3. **Configure App Group:**
   - In Xcode: Select the main app target > Signing & Capabilities
   - Add "App Groups" capability
   - Create/select group: `group.com.whio.KetoMacroTracker`
   - Repeat for the widget extension target

4. **Share Code:**
   - Add `WidgetDataService.swift` to both targets
   - Add `MacroCalculations.swift` to both targets (for widget data service)

5. **Build and Test:**
   - Build both targets
   - Long press on home screen > Add Widget > Keto Macros
   - Choose widget size (Small, Medium, or Large)

## Widget Features

- **Small Widget:** Shows net carbs with progress
- **Medium Widget:** Shows net carbs + quick stats (protein, fat, calories, fasting)
- **Large Widget:** Full dashboard preview with all macros, water, and fasting

Widget updates automatically when you log food, add water, or start/end fasting.

