# Keto Macro Tracker

A comprehensive iOS app for tracking keto macros, logging food intake, and managing your ketogenic diet journey.

## Features

- 🍽️ **Food Logging**: Search and log foods from USDA and OpenFoodFacts databases
- 📊 **Macro Tracking**: Track protein, carbs, fat, and calories with net carb calculations
- ⚡ **Quick Add**: Save frequently eaten foods for quick logging
- 🍱 **Custom Meals**: Create and save custom meals with multiple ingredients
- 📈 **Historical Data**: View trends and historical nutrition data
- 🎯 **Goal Tracking**: Set and track macro goals based on your profile
- 📱 **Barcode Scanner**: Scan barcodes to quickly find products
- 🏥 **HealthKit Integration**: Sync nutrition data with Apple Health
- 📱 **Widgets**: Home screen widgets for quick macro overview
- 🎓 **Tutorials**: Built-in tutorials to help you get started

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/KetoMacroTracker.git
   cd KetoMacroTracker
   ```

2. Open the project in Xcode:
   ```bash
   open KetoMacroTracker.xcodeproj
   ```

3. Configure API Keys:
   - Copy `KetoMacroTracker/Services/APIKeys.plist.example` to `KetoMacroTracker/Services/APIKeys.plist`
   - Add your USDA FoodData Central API key (see [README_API_KEYS.md](README_API_KEYS.md) for details)

4. Build and run the project in Xcode

## Project Structure

```
KetoMacroTracker/
├── KetoMacroTracker/
│   ├── Models/          # Data models and managers
│   ├── Views/           # SwiftUI views
│   ├── Services/        # API services and external integrations
│   ├── Utils/           # Utility functions
│   └── Widgets/         # Home screen widgets
├── KetoMacroTrackerTests/
└── README.md
```

## API Keys

This app uses the following APIs:
- **USDA FoodData Central API**: For food nutrition data
- **OpenFoodFacts API**: For barcode scanning and international products

See [README_API_KEYS.md](README_API_KEYS.md) for setup instructions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- USDA FoodData Central for nutrition data
- OpenFoodFacts for barcode scanning
- Apple HealthKit for health data integration

