//
//  OnboardingOverlayView.swift
//  Keto Macro Tracker
//
//  Interactive onboarding overlay for first-time users
//

import SwiftUI

struct OnboardingOverlayView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        if onboardingManager.isOnboardingActive, let step = onboardingManager.currentStep {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Highlight overlay
                if onboardingManager.showHighlight, let highlightId = onboardingManager.currentHighlight {
                    HighlightView(elementId: highlightId)
                        .allowsHitTesting(false)
                }
                
                // Onboarding card
                VStack {
                    switch step.position {
                    case .topPosition:
                        Spacer()
                    case .centerPosition:
                        Spacer()
                    case .bottomPosition:
                        EmptyView()
                    case .custom(_):
                        EmptyView()
                    }
                    
                    OnboardingCard(step: step)
                        .padding()
                        .transition(.move(edge: {
                            switch step.position {
                            case .bottomPosition:
                                return .bottom
                            default:
                                return .top
                            }
                        }()).combined(with: .opacity))
                    
                    switch step.position {
                    case .topPosition:
                        EmptyView()
                    case .centerPosition:
                        Spacer()
                    case .bottomPosition:
                        Spacer()
                    case .custom(_):
                        EmptyView()
                    }
                }
                .allowsHitTesting(true)
            }
            .onAppear {
                // Navigate to the target tab
                if selectedTab != step.targetTab {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = step.targetTab
                    }
                }
                
                // Show highlight after navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onboardingManager.currentHighlight = step.highlightElement
                    onboardingManager.showHighlight = step.highlightElement != nil
                }
            }
        }
    }
}

struct OnboardingCard: View {
    let step: OnboardingStep
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GETTING STARTED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(step.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    onboardingManager.skipOnboarding()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Description
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * onboardingManager.progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            // Navigation buttons
            HStack {
                Button(action: {
                    onboardingManager.previousStep()
                }) {
                    Text("Previous")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(onboardingManager.currentStepIndex == 0)
                .opacity(onboardingManager.currentStepIndex == 0 ? 0.5 : 1.0)
                
                Spacer()
                
                Text(onboardingManager.progressText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    onboardingManager.nextStep()
                }) {
                    Text("Next")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 400)
    }
}

// Reuse the HighlightView from DemoOverlayView
extension OnboardingOverlayView {
    struct HighlightView: View {
        let elementId: String
        @State private var pulseScale: CGFloat = 1.0
        @State private var opacity: Double = 0.7
        
        var body: some View {
            GeometryReader { geometry in
                let highlightFrame = getHighlightFrame(for: elementId, in: geometry)
                
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: highlightFrame.width + 20, height: highlightFrame.height + 20)
                        .position(x: highlightFrame.midX, y: highlightFrame.midY)
                        .blur(radius: 10)
                    
                    // Main highlight
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.15))
                        )
                        .frame(width: highlightFrame.width, height: highlightFrame.height)
                        .position(x: highlightFrame.midX, y: highlightFrame.midY)
                        .scaleEffect(pulseScale)
                        .opacity(opacity)
                }
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .onAppear {
                    pulseScale = 1.05
                    withAnimation {
                        opacity = 1.0
                    }
                }
            }
        }
        
        private func getHighlightFrame(for elementId: String, in geometry: GeometryProxy) -> CGRect {
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let tabBarHeight: CGFloat = 49
            let tabBarY = screenHeight - tabBarHeight - safeAreaBottom
            
            switch elementId {
            case "macro_rings":
                return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 200, width: 280, height: 200)
            case "add_food_button":
                return CGRect(x: screenWidth - 50, y: tabBarY - 80, width: 60, height: 60)
            case "insights_tab":
                let tabWidth = screenWidth / 5
                return CGRect(x: tabWidth * 1.5, y: tabBarY, width: tabWidth, height: tabBarHeight)
            case "profile_tab":
                let tabWidth = screenWidth / 5
                return CGRect(x: tabWidth * 4.5, y: tabBarY, width: tabWidth, height: tabBarHeight)
            default:
                return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 200, height: 100)
            }
        }
    }
}

#Preview {
    OnboardingOverlayView(selectedTab: .constant(0))
}

