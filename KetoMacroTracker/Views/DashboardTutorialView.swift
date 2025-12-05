//
//  DashboardTutorialView.swift
//  Keto Macro Tracker
//
//  Simple tutorial overlay for the main dashboard explaining how to use the app
//

import SwiftUI

struct DashboardTutorialView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    
    private let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            title: "How to Add Food",
            description: "Tap the green + button at the bottom right to search for foods, scan barcodes, or manually enter nutrition information.",
            highlightElement: "add_food_button"
        ),
        TutorialStep(
            title: "IMPORTANT: Serving Size Selection",
            description: "When you select a food, you MUST choose the correct serving size and unit (grams, ounces, cups, etc.). The macros shown are for the amount YOU select - this is crucial for accurate tracking!\n\nAlways adjust the serving size before adding food to your log.",
            highlightElement: "serving_selector"
        ),
        TutorialStep(
            title: "How to Log Food",
            description: "After selecting your serving size, tap 'Add to Food Log' to save the food with the exact macros for your chosen amount. The food will appear in your daily log below.",
            highlightElement: "add_button"
        ),
        TutorialStep(
            title: "Save to Quick Add",
            description: "After adding a food, you can tap the star icon to save it as a favorite. This allows you to quickly add the same food later without searching again. You can still adjust the serving size when adding from Quick Add.",
            highlightElement: "quick_add_button"
        ),
        TutorialStep(
            title: "You're All Set!",
            description: "Remember:\n• Always select serving size before adding\n• Save frequently used foods as favorites\n• Serving size determines your actual macros\n\nStart tracking your meals now!",
            highlightElement: nil
        )
    ]
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissing by tapping outside
                }
            
            if currentStep < tutorialSteps.count {
                let step = tutorialSteps[currentStep]
                
                VStack {
                    Spacer()
                    
                    // Tutorial card
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        Text(step.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Description
                        Text(step.description)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<tutorialSteps.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Navigation buttons
                        HStack(spacing: 12) {
                            if currentStep > 0 {
                                Button("Previous") {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button(currentStep == tutorialSteps.count - 1 ? "Got It!" : "Next") {
                                if currentStep == tutorialSteps.count - 1 {
                                    isPresented = false
                                } else {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let highlightElement: String?
}

#Preview {
    DashboardTutorialView(isPresented: .constant(true))
}

