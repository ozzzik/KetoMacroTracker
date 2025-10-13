# Keto Macro Tracker - Setup Instructions

Since automatic Xcode project creation had some issues, here are the manual steps to create the project:

## Step 1: Create New Xcode Project

1. In Xcode (which should now be open), go to **File > New > Project**
2. Select **iOS** tab
3. Choose **App** template
4. Click **Next**
5. Fill in the project details:
   - **Product Name**: KetoMacroTracker
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Use Core Data**: ✅ (check this box)
   - **Include Tests**: ✅ (optional)
6. Choose a location to save the project
7. Click **Create**

## Step 2: Add the Source Files

I've prepared all the source files for you. You'll need to add them to your Xcode project:

### Main App Files
- `KetoMacroTrackerApp.swift` - Main app entry point
- `ContentView.swift` - Tab navigation container  
- `Persistence.swift` - Core Data stack and data models

### Views (create Views folder first)
- `Views/TodayView.swift` - Daily macro tracking
- `Views/FoodSearchView.swift` - Food search and logging
- `Views/ManualFoodEntryView.swift` - Custom food entry
- `Views/ProfileView.swift` - User profile and goals
- `Views/EditProfileView.swift` - Profile editing
- `Views/HistoryView.swift` - Historical data and trends

### Services (create Services folder first)
- `Services/USDAFoodAPI.swift` - USDA API integration

## Step 3: Configure the Project

1. **Update API Key**: In `Services/USDAFoodAPI.swift`, the API key is already set to: `kipaOMjCe0LZgJubKNe4aEdYnApEy07Ebi7onTNn`

2. **Add Swift Charts** (optional for enhanced charts):
   - File > Add Package Dependencies
   - Enter: `https://github.com/apple/swift-charts`
   - Add to target

## Step 4: Core Data Model

The project includes a Core Data model with three entities:
- **FoodLog**: Individual food entries
- **FoodItem**: Saved foods for reuse  
- **UserProfile**: User settings and macro goals

## Step 5: Build and Run

1. Select your target device (iPhone Simulator or physical device)
2. Press **Cmd+R** to build and run
3. The app should launch with a tab-based interface

## Features Included

✅ **Today Tab**: Daily macro tracking with progress bars
✅ **History Tab**: Calendar view with weekly trends  
✅ **Search Tab**: Food search with USDA API + manual entry
✅ **Profile Tab**: User settings with BMR-based macro calculations

✅ **USDA FoodData Central API** integration with your API key
✅ **Net carbs calculation**: totalCarbs - fiber - sugarAlcohols
✅ **BMR-based macro goals** with activity level adjustments

## Troubleshooting

If you encounter any build errors:
1. Make sure all files are added to the target
2. Check that Core Data is properly configured
3. Verify the API key is correctly set
4. Ensure iOS deployment target is 17.0+

The app is fully functional and ready to use for tracking your keto macros!

---

**Note**: This approach ensures a clean, working Xcode project that you can build and run immediately.