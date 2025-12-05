import SwiftUI
import Combine

// MARK: - Guided Tour Step Models
struct GuidedStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let instruction: String
    let action: TourAction
    let targetView: String? // Which view/sheet to show
    let isInteractive: Bool
    let canSkip: Bool
    
    enum TourAction: Equatable {
        case tapButton(String) // Button ID to tap
        case openSheet(String) // Sheet to open
        case navigateToView(String) // View to navigate to
        case waitForUser // Wait for user to complete action
        case complete // Tour complete
    }
}

// MARK: - Guided Tour Manager
class GuidedTourManager: ObservableObject {
    @Published var isShowingTour = false
    @Published var currentStepIndex = 0
    @Published var hasCompletedTour = false
    @Published var currentInstruction: String = ""
    @Published var showActionButton = false
    @Published var actionButtonText = "Next"
    @Published var canGoBack = false
    
    private let userDefaults = UserDefaults.standard
    private let tourCompletedKey = "guided_tour_completed"
    
    init() {
        loadTourState()
    }
    
    // MARK: - Guided Tour Steps
    lazy var guidedSteps: [GuidedStep] = [
        GuidedStep(
            title: "Welcome to KetoMacroTracker",
            instruction: "This guided tour will demonstrate the core functionality of the app. Follow the instructions to learn how to log foods and track your macros.",
            action: .waitForUser,
            targetView: nil,
            isInteractive: false,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 1: Adding Foods",
            instruction: "Tap the plus button to access food logging options. You can search the USDA database, scan product barcodes, or manually enter nutrition information.",
            action: .tapButton("plus_button"),
            targetView: "food_search",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 2: Food Search",
            instruction: "The search interface provides three methods:\n• Text search: Enter food names to query the USDA database\n• Barcode scanning: Use the camera to scan product barcodes\n• Manual entry: Input nutrition values directly from food labels\n\nSearch for a food item to see results.",
            action: .waitForUser,
            targetView: "food_search",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 3: Selecting a Food",
            instruction: "Each search result displays three action buttons:\n• Add: Log the food to today's food log\n• Quick Add: Save the food as a favorite for future use\n• Manual: Edit nutrition values before adding\n\nSelect a food item and tap 'Add'.",
            action: .waitForUser,
            targetView: "food_search",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 4: Setting Serving Size",
            instruction: "The serving size selector allows you to:\n• Adjust quantity using the slider or text input\n• Select measurement units (grams, ounces, cups, etc.)\n• View real-time macro calculations as you adjust\n\nSet your desired serving size and tap 'Add to Today'.",
            action: .waitForUser,
            targetView: "food_search",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 5: Quick Add Feature",
            instruction: "Quick Add provides rapid access to frequently consumed foods. Foods saved to Quick Add are organized by category for efficient navigation.",
            action: .tapButton("star_button"),
            targetView: "quick_add",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 6: Quick Add Categories",
            instruction: "Quick Add organizes saved foods into categories such as Breakfast, Lunch, Protein, Vegetables, and more. This categorization streamlines food logging for common meal patterns.\n\nBrowse the available categories.",
            action: .waitForUser,
            targetView: "quick_add",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 7: Adding from Quick Add",
            instruction: "When selecting a food from Quick Add:\n• Serving size can be adjusted before logging\n• Macro values update in real-time\n• Tap to add the food to today's log\n\nAdd a food item from Quick Add to your log.",
            action: .waitForUser,
            targetView: "quick_add",
            isInteractive: true,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Step 8: Dashboard Overview",
            instruction: "The dashboard displays:\n• Daily macro progress rings showing progress toward goals\n• Total calories and macro breakdowns\n• Complete food log for the current day\n• Quick stats and progress indicators\n\nReview your dashboard to monitor your daily progress.",
            action: .waitForUser,
            targetView: nil,
            isInteractive: false,
            canSkip: true
        ),
        
        GuidedStep(
            title: "Tour Complete",
            instruction: "You have completed the guided tour. You now understand:\n• How to search and add foods\n• How to use Quick Add for rapid logging\n• How to monitor your macro progress\n\nComplete your profile in Settings to receive personalized macro targets based on your body composition and goals.",
            action: .complete,
            targetView: nil,
            isInteractive: false,
            canSkip: false
        )
    ]
    
    // MARK: - Tour Control
    func startTour() {
        isShowingTour = true
        currentStepIndex = 0
        updateCurrentStep()
    }
    
    func nextStep() {
        if currentStepIndex < guidedSteps.count - 1 {
            currentStepIndex += 1
            updateCurrentStep()
        } else {
            completeTour()
        }
    }
    
    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            updateCurrentStep()
        }
    }
    
    func skipTour() {
        completeTour()
    }
    
    func completeTour() {
        hasCompletedTour = true
        isShowingTour = false
        saveTourState()
    }
    
    // MARK: - Current Step Management
    private func updateCurrentStep() {
        guard currentStepIndex < guidedSteps.count else { return }
        let step = guidedSteps[currentStepIndex]
        
        currentInstruction = step.instruction
        canGoBack = currentStepIndex > 0
        
        // Determine button text and visibility
        switch step.action {
        case .waitForUser:
            actionButtonText = "Continue"
            showActionButton = true
        case .tapButton(_):
            actionButtonText = "Tap the Button"
            showActionButton = true
        case .complete:
            actionButtonText = "Start Tracking!"
            showActionButton = true
        default:
            actionButtonText = "Next"
            showActionButton = true
        }
    }
    
    // MARK: - Current Step
    var currentStep: GuidedStep? {
        guard currentStepIndex < guidedSteps.count else { return nil }
        return guidedSteps[currentStepIndex]
    }
    
    var progress: Double {
        guard !guidedSteps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(guidedSteps.count)
    }
    
    var progressText: String {
        return "\(currentStepIndex + 1) of \(guidedSteps.count)"
    }
    
    // MARK: - Persistence
    private func loadTourState() {
        hasCompletedTour = userDefaults.bool(forKey: tourCompletedKey)
    }
    
    private func saveTourState() {
        userDefaults.set(hasCompletedTour, forKey: tourCompletedKey)
    }
    
    // MARK: - Reset for Testing
    func resetTour() {
        hasCompletedTour = false
        userDefaults.removeObject(forKey: tourCompletedKey)
    }
    
    // MARK: - Action Execution
    func executeCurrentAction() {
        guard let step = currentStep else { return }
        
        switch step.action {
        case .tapButton(let buttonId):
            // This would trigger the actual button tap
            // Implementation depends on how we handle the tour
            print("🔄 Tour: Should tap button with ID: \(buttonId)")
            
        case .openSheet(let sheetName):
            print("🔄 Tour: Should open sheet: \(sheetName)")
            
        case .navigateToView(let viewName):
            print("🔄 Tour: Should navigate to view: \(viewName)")
            
        case .waitForUser:
            // User has completed the action, move to next step
            nextStep()
            
        case .complete:
            completeTour()
        }
    }
}
