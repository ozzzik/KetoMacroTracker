import SwiftUI
import Combine

// MARK: - Tour Step Models
struct TourStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let targetElement: String // Identifier for the UI element to highlight
    let position: TourPosition
    let actionText: String?
    let isInteractive: Bool
    
    enum TourPosition {
        case top
        case bottom
        case left
        case right
        case center
    }
}

// MARK: - Walking Tour Manager
class WalkingTourManager: ObservableObject {
    @Published var isShowingTour = false
    @Published var currentStepIndex = 0
    @Published var hasCompletedTour = false
    @Published var highlightedElementId: String?
    @Published var tourOverlayOpacity: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    private let tourCompletedKey = "walking_tour_completed"
    
    init() {
        loadTourState()
    }
    
    // MARK: - Tour Steps
    lazy var tourSteps: [TourStep] = [
        TourStep(
            title: "Welcome to Your Dashboard",
            description: "This is your main screen where you'll track your daily macros and add food items.",
            targetElement: "dashboard_title",
            position: .top,
            actionText: "Let's start!",
            isInteractive: false
        ),
        
        TourStep(
            title: "Quick Add Favorites",
            description: "Tap the star button to quickly add your favorite foods that you've saved before.",
            targetElement: "star_button",
            position: .bottom,
            actionText: "Got it!",
            isInteractive: true
        ),
        
        TourStep(
            title: "Add New Food",
            description: "Tap the plus button to search for new foods, scan barcodes, or manually enter nutrition information.",
            targetElement: "plus_button",
            position: .bottom,
            actionText: "Show me!",
            isInteractive: true
        ),
        
        TourStep(
            title: "Your Daily Progress",
            description: "Here you can see how you're doing with your daily macro goals. Green means you're on track!",
            targetElement: "macro_progress",
            position: .center,
            actionText: "Looks good!",
            isInteractive: false
        ),
        
        TourStep(
            title: "Ready to Add Your First Food?",
            description: "Let's add a food item together. Tap the plus button to get started!",
            targetElement: "plus_button",
            position: .bottom,
            actionText: "Let's do it!",
            isInteractive: true
        )
    ]
    
    // MARK: - Tour Control
    func startTour() {
        isShowingTour = true
        currentStepIndex = 0
        updateHighlightedElement()
        animateOverlayIn()
    }
    
    func nextStep() {
        if currentStepIndex < tourSteps.count - 1 {
            currentStepIndex += 1
            updateHighlightedElement()
        } else {
            completeTour()
        }
    }
    
    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            updateHighlightedElement()
        }
    }
    
    func skipTour() {
        completeTour()
    }
    
    func completeTour() {
        hasCompletedTour = true
        isShowingTour = false
        highlightedElementId = nil
        animateOverlayOut()
        saveTourState()
    }
    
    // MARK: - Element Highlighting
    private func updateHighlightedElement() {
        guard currentStepIndex < tourSteps.count else { return }
        highlightedElementId = tourSteps[currentStepIndex].targetElement
    }
    
    private func animateOverlayIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            tourOverlayOpacity = 1.0
        }
    }
    
    private func animateOverlayOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            tourOverlayOpacity = 0.0
        }
    }
    
    // MARK: - Current Step
    var currentStep: TourStep? {
        guard currentStepIndex < tourSteps.count else { return nil }
        return tourSteps[currentStepIndex]
    }
    
    var progress: Double {
        guard !tourSteps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(tourSteps.count)
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
    
    // MARK: - Element Visibility Check
    func isElementHighlighted(_ elementId: String) -> Bool {
        return highlightedElementId == elementId
    }
}
