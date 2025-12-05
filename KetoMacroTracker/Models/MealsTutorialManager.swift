//
//  MealsTutorialManager.swift
//  Keto Macro Tracker
//
//  Tutorial manager for the Meals page
//

import Foundation
import SwiftUI

class MealsTutorialManager: ObservableObject {
    static let shared = MealsTutorialManager()
    
    @Published var isShowing = false
    @Published var currentStepIndex = 0
    
    private let hasCompletedMealsTutorialKey = "has_completed_meals_tutorial"
    
    private init() {}
    
    var hasCompletedTutorial: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedMealsTutorialKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedMealsTutorialKey)
        }
    }
    
    var tutorialSteps: [MealsTutorialStep] {
        [
            MealsTutorialStep(
                title: "Welcome to Quick Meals",
                description: "This page helps you discover keto-friendly meals and manage your custom meal plans. Let's explore the key features.",
                highlightElement: nil,
                position: .center
            ),
            MealsTutorialStep(
                title: "Understanding Macro Fit",
                description: "Each meal suggestion shows a 'fit' rating:\n\n• Perfect: Meal matches your remaining macros perfectly\n• Good: Meal fits well with your goals\n• Acceptable: Meal works but may need adjustment\n• Poor: Meal doesn't align well with remaining macros\n\nThe fit is calculated based on what you've already eaten today and the time of day.",
                highlightElement: "macro_fit_badge",
                position: .top
            ),
            MealsTutorialStep(
                title: "Meal Suggestions",
                description: "The app suggests meals based on:\n\n• Your remaining macros for the day\n• Time of day (breakfast, lunch, dinner)\n• Your macro goals and preferences\n\nTap any meal to see details and add it to your food log.",
                highlightElement: "meal_suggestions",
                position: .center
            ),
            MealsTutorialStep(
                title: "Why Use Templates?",
                description: "Templates save your favorite custom meals for quick access:\n\n• Create once, use many times\n• Perfect for meal prep planning\n• Adjust serving sizes each time you use them\n• Great for tracking recurring meals\n\nTap 'Templates' in the navigation bar to view and manage your saved templates.",
                highlightElement: "templates_section",
                position: .center
            ),
            MealsTutorialStep(
                title: "Custom Meals",
                description: "Create your own meals by combining multiple foods:\n\n• Build meals from foods you've logged\n• Save as templates for reuse\n• Perfect for tracking complex recipes\n• Adjust individual food servings\n\nTap the '+' button to create a new custom meal.",
                highlightElement: "create_custom_meal_button",
                position: .bottom
            ),
            MealsTutorialStep(
                title: "Filters & Categories",
                description: "Use the quick filters to find meals by:\n\n• Category (Breakfast, Lunch, Dinner, Snacks)\n• Prep time\n• Difficulty level\n\nFilter suggestions to match your needs and preferences.",
                highlightElement: "filter_section",
                position: .top
            ),
            MealsTutorialStep(
                title: "Remaining Macros",
                description: "The top card shows your remaining macros for today. This helps you choose meals that fit your daily goals. The app suggests meals that work with what you have left.",
                highlightElement: "remaining_macros_card",
                position: .top
            ),
            MealsTutorialStep(
                title: "You're All Set!",
                description: "You now know how to use the Meals page. Explore meal suggestions, create custom meals, and save templates for quick access. Happy meal planning!",
                highlightElement: nil,
                position: .center
            )
        ]
    }
    
    var currentStep: MealsTutorialStep? {
        guard currentStepIndex < tutorialSteps.count else { return nil }
        return tutorialSteps[currentStepIndex]
    }
    
    var progress: Double {
        guard !tutorialSteps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(tutorialSteps.count)
    }
    
    func show() {
        if !hasCompletedTutorial {
            isShowing = true
            currentStepIndex = 0
        }
    }
    
    func next() {
        if currentStepIndex < tutorialSteps.count - 1 {
            currentStepIndex += 1
        } else {
            complete()
        }
    }
    
    func previous() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }
    
    func skip() {
        complete()
    }
    
    func complete() {
        hasCompletedTutorial = true
        isShowing = false
        currentStepIndex = 0
    }
}

struct MealsTutorialStep {
    let title: String
    let description: String
    let highlightElement: String?
    let position: MessagePosition
    
    enum MessagePosition {
        case top
        case center
        case bottom
    }
}

