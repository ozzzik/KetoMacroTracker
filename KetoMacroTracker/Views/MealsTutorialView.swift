//
//  MealsTutorialView.swift
//  Keto Macro Tracker
//
//  Tutorial overlay for the Meals page
//

import SwiftUI

struct MealsTutorialView: View {
    @ObservedObject var tutorialManager = MealsTutorialManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        if tutorialManager.isShowing, let step = tutorialManager.currentStep {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Don't dismiss on background tap
                    }
                
                // Highlight overlay (if element is specified)
                if let element = step.highlightElement {
                    HighlightOverlay(elementId: element)
                }
                
                // Message card
                VStack {
                    if step.position == .top {
                        Spacer()
                    }
                    
                    TutorialMessageCard(
                        title: step.title,
                        description: step.description,
                        progress: tutorialManager.progress,
                        progressText: "\(tutorialManager.currentStepIndex + 1) of \(tutorialManager.tutorialSteps.count)",
                        onNext: {
                            tutorialManager.next()
                        },
                        onPrevious: {
                            tutorialManager.previous()
                        },
                        onSkip: {
                            tutorialManager.skip()
                            isPresented = false
                        },
                        showPrevious: tutorialManager.currentStepIndex > 0,
                        isLastStep: tutorialManager.currentStepIndex == tutorialManager.tutorialSteps.count - 1
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, step.position == .bottom ? 100 : 20)
                    
                    if step.position == .bottom {
                        Spacer()
                    }
                }
            }
            .transition(.opacity)
        }
    }
}

struct HighlightOverlay: View {
    let elementId: String
    
    var body: some View {
        // This would need to be implemented based on actual UI element positions
        // For now, we'll use a simple approach
        GeometryReader { geometry in
            let highlightFrame = getHighlightFrame(for: elementId, in: geometry)
            
            // Draw highlight around element
            Path { path in
                // Outer rectangle (full screen)
                path.addRect(geometry.frame(in: .local))
                // Inner rectangle (element to highlight) - reverse to create cutout
                path.addRoundedRect(in: highlightFrame, cornerSize: CGSize(width: 12, height: 12))
            }
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.6))
        }
    }
    
    private func getHighlightFrame(for elementId: String, in geometry: GeometryProxy) -> CGRect {
        let screenWidth = geometry.size.width
        let safeAreaTop = geometry.safeAreaInsets.top
        
        switch elementId {
        case "macro_fit_badge":
            return CGRect(x: screenWidth * 0.7, y: safeAreaTop + 200, width: 80, height: 30)
        case "meal_suggestions":
            return CGRect(x: 16, y: safeAreaTop + 300, width: screenWidth - 32, height: 200)
        case "templates_section":
            return CGRect(x: 16, y: safeAreaTop + 150, width: screenWidth - 32, height: 100)
        case "create_custom_meal_button":
            return CGRect(x: screenWidth - 80, y: safeAreaTop + 20, width: 60, height: 30)
        case "filter_section":
            return CGRect(x: 16, y: safeAreaTop + 120, width: screenWidth - 32, height: 60)
        case "remaining_macros_card":
            return CGRect(x: 16, y: safeAreaTop + 20, width: screenWidth - 32, height: 100)
        default:
            return CGRect.zero
        }
    }
}

struct TutorialMessageCard: View {
    let title: String
    let description: String
    let progress: Double
    let progressText: String
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    let showPrevious: Bool
    let isLastStep: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(AppColors.primary)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
            
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress text
                Text(progressText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                // Buttons
                HStack(spacing: 12) {
                    if showPrevious {
                        Button(action: onPrevious) {
                            Text("Previous")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(action: onNext) {
                        Text(isLastStep ? "Got it!" : "Next")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .cornerRadius(8)
                    }
                }
                
                // Skip button
                Button(action: onSkip) {
                    Text("Skip Tutorial")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

