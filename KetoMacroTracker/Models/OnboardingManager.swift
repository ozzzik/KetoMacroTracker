//
//  OnboardingManager.swift
//  Keto Macro Tracker
//
//  Interactive onboarding for first-time users
//

import Foundation
import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let targetTab: Int
    let highlightElement: String?
    let position: OnboardingPosition
    
    enum OnboardingPosition {
        case topPosition
        case bottomPosition
        case centerPosition
        case custom(CGRect)
    }
}

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var isOnboardingActive = false
    @Published var currentStepIndex = 0
    @Published var currentHighlight: String? = nil
    @Published var showHighlight = false
    
    private var _onboardingSteps: [OnboardingStep] = []
    private let hasCompletedOnboardingKey = "has_completed_onboarding"
    
    private init() {
        setupOnboardingSteps()
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
    var currentStep: OnboardingStep? {
        guard currentStepIndex < _onboardingSteps.count else { return nil }
        return _onboardingSteps[currentStepIndex]
    }
    
    var progress: Double {
        guard !_onboardingSteps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(_onboardingSteps.count)
    }
    
    var progressText: String {
        let totalSteps = _onboardingSteps.count
        return "\(currentStepIndex + 1) of \(totalSteps)"
    }
    
    // MARK: - Setup Onboarding Steps
    private func setupOnboardingSteps() {
        _onboardingSteps = [
            OnboardingStep(
                title: "Welcome to KetoMacroTracker",
                description: "Your personal macro tracking companion for the ketogenic diet. Let's take a quick tour of the key features.",
                targetTab: 0,
                highlightElement: nil,
                position: .centerPosition
            ),
            
            OnboardingStep(
                title: "Dashboard Overview",
                description: "This is your daily dashboard. Here you can see your macro progress, food log, hydration, and quick stats. The circular progress rings show how close you are to your daily goals.",
                targetTab: 0,
                highlightElement: "macro_rings",
                position: .topPosition
            ),
            
            OnboardingStep(
                title: "Add Food to Your Log",
                description: "Tap the green plus button to search for foods, scan barcodes, or manually enter nutrition information. This is how you'll log everything you eat.",
                targetTab: 0,
                highlightElement: "add_food_button",
                position: .bottomPosition
            ),
            
            OnboardingStep(
                title: "Track Your Progress",
                description: "The Insights tab shows trends, analytics, and predictions. Monitor your macro balance and ketosis indicators to stay on track.",
                targetTab: 1,
                highlightElement: "insights_tab",
                position: .bottomPosition
            ),
            
            OnboardingStep(
                title: "Save Favorite Foods",
                description: "The Meals tab lets you create custom meals, save favorites, and use Quick Add for frequently eaten foods. This saves time when logging.",
                targetTab: 2,
                highlightElement: nil,
                position: .centerPosition
            ),
            
            OnboardingStep(
                title: "View Your History",
                description: "The History tab shows your past food logs and daily summaries. Review your progress over time and identify patterns.",
                targetTab: 3,
                highlightElement: nil,
                position: .centerPosition
            ),
            
            OnboardingStep(
                title: "Configure Your Profile",
                description: "The Profile tab is where you set up your personal information, activity level, and goals. Accurate profile data ensures precise macro calculations.",
                targetTab: 4,
                highlightElement: "profile_tab",
                position: .bottomPosition
            ),
            
            OnboardingStep(
                title: "Important: Serving Sizes",
                description: "When adding foods, always select the correct serving size and unit. The macros shown are for the amount you select - this is crucial for accurate tracking!",
                targetTab: 0,
                highlightElement: nil,
                position: .centerPosition
            ),
            
            OnboardingStep(
                title: "You're All Set!",
                description: "Start by completing your profile, then begin logging foods. Remember to check serving sizes and save your favorites for quick access. Happy tracking!",
                targetTab: 0,
                highlightElement: nil,
                position: .centerPosition
            )
        ]
    }
    
    // MARK: - Onboarding Control
    func startOnboarding() {
        guard !hasCompletedOnboarding else { return }
        isOnboardingActive = true
        currentStepIndex = 0
    }
    
    func nextStep() {
        guard currentStepIndex < _onboardingSteps.count - 1 else {
            completeOnboarding()
            return
        }
        currentStepIndex += 1
    }
    
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    func completeOnboarding() {
        isOnboardingActive = false
        hasCompletedOnboarding = true
        currentStepIndex = 0
        currentHighlight = nil
        showHighlight = false
    }
    
    // MARK: - Reset for Testing
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
    }
}

