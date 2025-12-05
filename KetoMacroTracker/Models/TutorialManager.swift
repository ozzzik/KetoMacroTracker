import SwiftUI
import Combine

// MARK: - Tutorial Models
struct TutorialSlide: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let content: String
    let imageName: String?
    let actionText: String?
    let isInteractive: Bool
    let slideType: TutorialSlideType
    
    enum TutorialSlideType {
        case welcome
        case macroExplanation
        case unitsExplanation
        case calculationExample
        case featuresOverview
        case quickStart
    }
}

// MARK: - Tutorial Manager
class TutorialManager: ObservableObject {
    @Published var isShowingTutorial = false
    @Published var currentSlideIndex = 0
    @Published var hasCompletedTutorial = false
    
    private let userDefaults = UserDefaults.standard
    private let tutorialCompletedKey = "tutorial_completed"
    
    init() {
        loadTutorialState()
    }
    
    // MARK: - Tutorial Slides
    lazy var tutorialSlides: [TutorialSlide] = [
        TutorialSlide(
            title: "Welcome to KetoMacroTracker",
            subtitle: "Professional Macro Tracking for Ketogenic Diets",
            content: "KetoMacroTracker provides comprehensive macro tracking and nutritional analysis designed for individuals following a ketogenic diet. Complete your profile to receive personalized macro targets based on your body composition, activity level, and goals.",
            imageName: "chart.bar.fill",
            actionText: nil,
            isInteractive: false,
            slideType: .welcome
        ),
        
        TutorialSlide(
            title: "Macro Calculations",
            subtitle: "Scientifically-Based Targets",
            content: "Your daily macro targets are calculated using:\n\n• **Protein**: Based on activity level and body weight (1.5-2.3g per kg)\n• **Net Carbohydrates**: Fixed at 30g to maintain ketosis\n• **Fat**: Calculated to meet remaining caloric needs\n• **Total Calories**: Derived from BMR, TDEE, and goal multiplier\n\nAll calculations use the Mifflin-St Jeor equation for BMR and activity multipliers for TDEE.",
            imageName: "function",
            actionText: nil,
            isInteractive: false,
            slideType: .macroExplanation
        ),
        
        TutorialSlide(
            title: "Net Carbohydrate Calculation",
            subtitle: "Essential for Ketosis",
            content: "**Net Carbs = Total Carbohydrates - Dietary Fiber - Sugar Alcohols**\n\nExample calculation:\n• Total carbohydrates: 20g\n• Dietary fiber: 8g\n• Sugar alcohols: 2g\n• **Net carbs: 10g**\n\nOnly net carbohydrates are counted toward your daily 30g limit. This calculation is performed automatically for all logged foods.",
            imageName: "number.circle.fill",
            actionText: nil,
            isInteractive: false,
            slideType: .calculationExample
        ),
        
        TutorialSlide(
            title: "Food Tracking Methods",
            subtitle: "Multiple Data Sources",
            content: "• **USDA Database**: Comprehensive nutritional database with over 300,000 foods\n• **OpenFoodFacts**: International food database with barcode scanning\n• **Barcode Scanner**: Instant lookup using product barcodes\n• **Manual Entry**: Custom nutrition values from food labels\n• **Quick Add**: Saved favorites for rapid logging\n• **Custom Meals**: Create and save meal combinations",
            imageName: "list.bullet.rectangle.fill",
            actionText: nil,
            isInteractive: false,
            slideType: .featuresOverview
        ),
        
        TutorialSlide(
            title: "Units and Conversions",
            subtitle: "Flexible Measurement Support",
            content: "The app supports multiple measurement units with automatic conversion:\n\n• **Weight**: grams, ounces, pounds\n• **Volume**: cups, tablespoons, teaspoons, milliliters, fluid ounces\n• **Count**: individual items, pieces\n\nAll conversions use standard nutritional conversion factors to ensure accurate macro calculations regardless of the selected unit.",
            imageName: "scalemass.fill",
            actionText: nil,
            isInteractive: false,
            slideType: .unitsExplanation
        ),
        
        TutorialSlide(
            title: "Getting Started",
            subtitle: "Initial Setup",
            content: "To begin tracking:\n\n1. **Complete Profile**: Enter weight, height, age, gender, activity level, and goal\n2. **Review Macros**: Verify your calculated macro targets\n3. **Log Foods**: Use search, barcode scanning, or manual entry\n4. **Monitor Progress**: Track daily macros against your targets\n5. **Review Analytics**: Access insights and trends in the Insights tab\n\nAccurate profile data ensures precise macro calculations.",
            imageName: "checkmark.circle.fill",
            actionText: "Continue",
            isInteractive: true,
            slideType: .quickStart
        )
    ]
    
    // MARK: - Tutorial State Management
    func showTutorial() {
        isShowingTutorial = true
        currentSlideIndex = 0
    }
    
    func hideTutorial() {
        isShowingTutorial = false
    }
    
    func nextSlide() {
        if currentSlideIndex < tutorialSlides.count - 1 {
            currentSlideIndex += 1
        } else {
            completeTutorial()
        }
    }
    
    func previousSlide() {
        if currentSlideIndex > 0 {
            currentSlideIndex -= 1
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        hasCompletedTutorial = true
        isShowingTutorial = false
        saveTutorialState()
    }
    
    // MARK: - Persistence
    private func loadTutorialState() {
        hasCompletedTutorial = userDefaults.bool(forKey: tutorialCompletedKey)
    }
    
    private func saveTutorialState() {
        userDefaults.set(hasCompletedTutorial, forKey: tutorialCompletedKey)
    }
    
    // MARK: - Reset for Testing
    func resetTutorial() {
        hasCompletedTutorial = false
        userDefaults.removeObject(forKey: tutorialCompletedKey)
    }
}
