//
//  DemoModeManager.swift
//  Keto Macro Tracker
//
//  Automated demo mode for video tutorials
//

import Foundation
import SwiftUI
import Combine

struct DemoStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let targetView: DemoView
    let highlightElement: String? // Element ID to highlight
    let action: DemoAction
    let duration: TimeInterval
    let delay: TimeInterval
    
    enum DemoView: String {
        case dashboard = "Dashboard"
        case foodSearch = "FoodSearch"
        case quickAdd = "QuickAdd"
        case profile = "Profile"
        case insights = "Insights"
    }
    
    enum DemoAction {
        case show
        case tap
        case navigate
        case highlight
        case wait
        case complete
    }
}

class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    @Published var isDemoActive = false
    @Published var isPaused = false
    @Published var currentStepIndex = 0
    @Published var currentHighlight: String? = nil
    @Published var showHighlight = false
    @Published var demoMessage: String = ""
    @Published var shouldNavigate: Bool = false
    @Published var targetTab: Int? = nil
    
    private var demoSteps: [DemoStep] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentTimer: Timer?
    
    private init() {
        setupDemoSteps()
    }
    
    // MARK: - Demo Steps Setup
    private func setupDemoSteps() {
        demoSteps = [
            DemoStep(
                title: "Welcome to KetoMacroTracker",
                description: "Professional macro tracking for ketogenic diets",
                targetView: .dashboard,
                highlightElement: nil,
                action: .show,
                duration: 2.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Step 1: Search for Food",
                description: "Tap the plus button to search the USDA database, scan barcodes, or manually enter foods",
                targetView: .dashboard,
                highlightElement: "add_food_button",
                action: .highlight,
                duration: 3.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Step 2: Select a Food Item",
                description: "Browse search results and tap on any food to view its nutrition information",
                targetView: .foodSearch,
                highlightElement: "food_result",
                action: .navigate,
                duration: 3.0,
                delay: 1.0
            ),
            
            DemoStep(
                title: "Step 3: Choose Serving Size",
                description: "IMPORTANT: Adjust the amount and select the unit (grams, ounces, cups, etc.). The macros update in real-time as you change the serving size.",
                targetView: .foodSearch,
                highlightElement: "serving_selector",
                action: .highlight,
                duration: 5.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Step 4: Add to Food Log",
                description: "Once you've selected your serving size, tap 'Add to Today' to log the food with the exact macros for your chosen amount.",
                targetView: .foodSearch,
                highlightElement: "add_button",
                action: .highlight,
                duration: 4.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Step 5: Save as Favorite (Quick Add)",
                description: "IMPORTANT: After adding a food, you can tap 'Quick Add' (star icon) to save it as a favorite. This allows you to quickly add the same food later without searching again.",
                targetView: .foodSearch,
                highlightElement: "quick_add_button",
                action: .highlight,
                duration: 5.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Step 6: Using Saved Favorites",
                description: "Tap the star button on the dashboard to access your saved foods. When you select a saved food, you can adjust the serving size before adding it to your log.",
                targetView: .quickAdd,
                highlightElement: "quick_add_categories",
                action: .navigate,
                duration: 4.0,
                delay: 1.0
            ),
            
            DemoStep(
                title: "Step 7: Adjust Serving Size from Quick Add",
                description: "When adding from Quick Add, you can change the serving size just like when searching. Select your desired amount and unit, then add to your log.",
                targetView: .quickAdd,
                highlightElement: "serving_selector",
                action: .highlight,
                duration: 4.0,
                delay: 0.5
            ),
            
            DemoStep(
                title: "Review: Key Points",
                description: "Remember:\n• Always select your serving size before adding\n• Save frequently used foods as favorites\n• Serving size determines your actual macros\n• You can adjust servings from both search and Quick Add",
                targetView: .dashboard,
                highlightElement: nil,
                action: .navigate,
                duration: 5.0,
                delay: 1.0
            ),
            
            DemoStep(
                title: "Demo Complete",
                description: "You now understand how to search, select serving sizes, add foods, and save favorites for quick access.",
                targetView: .dashboard,
                highlightElement: nil,
                action: .complete,
                duration: 2.0,
                delay: 0.5
            )
        ]
    }
    
    // MARK: - Demo Control
    func startDemo() {
        guard !isDemoActive else { return }
        
        isDemoActive = true
        currentStepIndex = 0
        executeCurrentStep()
    }
    
    func stopDemo() {
        isDemoActive = false
        isPaused = false
        currentStepIndex = 0
        currentHighlight = nil
        showHighlight = false
        demoMessage = ""
        shouldNavigate = false
        targetTab = nil
        currentTimer?.invalidate()
        currentTimer = nil
    }
    
    func pauseDemo() {
        guard isDemoActive && !isPaused else { return }
        isPaused = true
        currentTimer?.invalidate()
        currentTimer = nil
    }
    
    func resumeDemo() {
        guard isDemoActive && isPaused else { return }
        isPaused = false
        // Continue from where we left off
        executeCurrentStep()
    }
    
    private func executeCurrentStep() {
        guard isDemoActive, currentStepIndex < demoSteps.count else {
            stopDemo()
            return
        }
        
        let step = demoSteps[currentStepIndex]
        
        // Set message
        demoMessage = step.description
        
        // Handle delay
        DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) { [weak self] in
            guard let self = self, self.isDemoActive else { return }
            
            // Set target tab first, before executing action
            let targetTabIndex: Int
            switch step.targetView {
            case .dashboard:
                targetTabIndex = 0
            case .foodSearch:
                targetTabIndex = 0 // Food search opens from dashboard
            case .quickAdd:
                targetTabIndex = 2
            case .insights:
                targetTabIndex = 1
            case .profile:
                targetTabIndex = 4
            }
            
            // Navigate immediately if needed
            DispatchQueue.main.async {
                self.targetTab = targetTabIndex
            }
            
            // Execute action after a brief delay to allow navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.isDemoActive else { return }
                
                switch step.action {
                case .show:
                    self.currentHighlight = step.highlightElement
                    self.showHighlight = step.highlightElement != nil
                    self.shouldNavigate = false
                    
                case .navigate:
                    self.currentHighlight = step.highlightElement
                    self.showHighlight = step.highlightElement != nil
                    self.shouldNavigate = true
                    
                case .highlight:
                    self.currentHighlight = step.highlightElement
                    self.showHighlight = true
                    self.shouldNavigate = false
                    
                case .wait:
                    self.shouldNavigate = false
                    break
                    
                case .complete:
                    self.showHighlight = false
                    self.currentHighlight = nil
                    self.shouldNavigate = false
                    
                case .tap:
                    self.currentHighlight = step.highlightElement
                    self.showHighlight = true
                    self.shouldNavigate = false
                }
            }
            
            // Schedule next step
            self.currentTimer = Timer.scheduledTimer(withTimeInterval: step.duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isDemoActive else { return }
                self.nextStep()
            }
        }
    }
    
    private func nextStep() {
        guard isDemoActive else { return }
        
        currentStepIndex += 1
        
        if currentStepIndex >= demoSteps.count {
            stopDemo()
        } else {
            executeCurrentStep()
        }
    }
    
    var currentStep: DemoStep? {
        guard currentStepIndex < demoSteps.count else { return nil }
        return demoSteps[currentStepIndex]
    }
    
    var progress: Double {
        guard !demoSteps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(demoSteps.count)
    }
    
    var progressText: String {
        return "\(currentStepIndex + 1) / \(demoSteps.count)"
    }
}

