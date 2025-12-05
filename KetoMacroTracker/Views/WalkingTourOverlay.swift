import SwiftUI

struct WalkingTourOverlay: View {
    @ObservedObject var tourManager: WalkingTourManager
    @State private var tooltipOffset: CGFloat = 0
    @State private var tooltipOpacity: Double = 0
    
    var body: some View {
        if tourManager.isShowingTour {
            ZStack {
                // Dark overlay with spotlight effect
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .ignoresSafeArea()
                    .opacity(tourManager.tourOverlayOpacity)
                
                // Tour tooltip
                if let currentStep = tourManager.currentStep {
                    VStack {
                        Spacer()
                        
                        // Tooltip content
                        TourTooltip(
                            step: currentStep,
                            offset: tooltipOffset,
                            opacity: tooltipOpacity,
                            onNext: {
                                tourManager.nextStep()
                            },
                            onPrevious: {
                                tourManager.previousStep()
                            },
                            onSkip: {
                                tourManager.skipTour()
                            },
                            canGoBack: tourManager.currentStepIndex > 0,
                            isLastStep: tourManager.currentStepIndex == tourManager.tourSteps.count - 1
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
            .onAppear {
                animateTooltipIn()
            }
            .onChange(of: tourManager.currentStepIndex) {
                animateTooltipIn()
            }
        }
    }
    
    private func animateTooltipIn() {
        tooltipOffset = 50
        tooltipOpacity = 0
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            tooltipOffset = 0
            tooltipOpacity = 1
        }
    }
}

// MARK: - Tour Tooltip
struct TourTooltip: View {
    let step: TourStep
    let offset: CGFloat
    let opacity: Double
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    let canGoBack: Bool
    let isLastStep: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index <= stepIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            // Content
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Action button
            if let actionText = step.actionText {
                Button(action: onNext) {
                    Text(actionText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(25)
                }
            }
            
            // Navigation controls
            HStack {
                // Previous button
                if canGoBack {
                    Button(action: onPrevious) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Spacer()
                }
                
                Spacer()
                
                // Skip button
                Button(action: onSkip) {
                    Text("Skip Tour")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .offset(y: offset)
        .opacity(opacity)
    }
    
    private var stepIndex: Int {
        // This would need to be passed in or calculated based on the current step
        return 2 // Placeholder - would need proper implementation
    }
}

// MARK: - Element Highlighter
struct TourElementHighlighter: ViewModifier {
    let elementId: String
    let tourManager: WalkingTourManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Highlight ring when this element is targeted
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .scaleEffect(tourManager.isElementHighlighted(elementId) ? 1.2 : 1.0)
                    .opacity(tourManager.isElementHighlighted(elementId) ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: tourManager.highlightedElementId)
                    .shadow(color: .white.opacity(0.5), radius: 10)
                    .padding(-8)
            )
            .scaleEffect(tourManager.isElementHighlighted(elementId) ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: tourManager.isElementHighlighted(elementId))
    }
}

// MARK: - View Extension
extension View {
    func tourHighlight(id: String, tourManager: WalkingTourManager) -> some View {
        self.modifier(TourElementHighlighter(elementId: id, tourManager: tourManager))
    }
}

// MARK: - Preview
struct WalkingTourOverlay_Previews: PreviewProvider {
    static var previews: some View {
        WalkingTourOverlay(tourManager: WalkingTourManager())
    }
}
