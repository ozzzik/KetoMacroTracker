import SwiftUI

struct GuidedTourOverlay: View {
    @ObservedObject var tourManager: GuidedTourManager
    @State private var cardOffset: CGFloat = 300
    @State private var cardOpacity: Double = 0
    @State private var pulseAnimation = false
    
    var body: some View {
        if tourManager.isShowingTour {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Allow tapping through to underlying UI
                    }
                
                // Guided instruction card
                VStack {
                    Spacer()
                    
                    GuidedInstructionCard(
                        tourManager: tourManager,
                        offset: cardOffset,
                        opacity: cardOpacity,
                        onNext: {
                            tourManager.executeCurrentAction()
                        },
                        onPrevious: {
                            tourManager.previousStep()
                        },
                        onSkip: {
                            tourManager.skipTour()
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                animateCardIn()
            }
            .onChange(of: tourManager.currentStepIndex) {
                animateCardIn()
            }
        }
    }
    
    private func animateCardIn() {
        cardOffset = 300
        cardOpacity = 0
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            cardOffset = 0
            cardOpacity = 1
        }
    }
}

// MARK: - Guided Instruction Card
struct GuidedInstructionCard: View {
    @ObservedObject var tourManager: GuidedTourManager
    let offset: CGFloat
    let opacity: Double
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guided Tour")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(tourManager.progressText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Progress bar
                VStack(alignment: .trailing, spacing: 4) {
                    ProgressView(value: tourManager.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 120)
                    
                    Text("\(Int(tourManager.progress * 100))% Complete")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Main content
            if let step = tourManager.currentStep {
                VStack(spacing: 16) {
                    // Title
                    Text(step.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Instruction
                    Text(step.instruction)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Main action button
                if tourManager.showActionButton {
                    Button(action: onNext) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                            Text(tourManager.actionButtonText)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                
                // Navigation controls
                HStack {
                    // Previous button
                    if tourManager.canGoBack {
                        Button(action: onPrevious) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Skip button
                    if let step = tourManager.currentStep, step.canSkip {
                        Button(action: onSkip) {
                            Text("Skip Tour")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .offset(y: offset)
        .opacity(opacity)
    }
}

// MARK: - Tour Action Handler
struct TourActionHandler: ViewModifier {
    @ObservedObject var tourManager: GuidedTourManager
    let buttonId: String
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // Check if this is the button the tour is waiting for
                if let step = tourManager.currentStep,
                   case .tapButton(let targetButtonId) = step.action,
                   targetButtonId == buttonId {
                    // Execute the tour action
                    tourManager.executeCurrentAction()
                }
            }
    }
}

// MARK: - View Extension for Tour Actions
extension View {
    func tourAction(buttonId: String, tourManager: GuidedTourManager) -> some View {
        self.modifier(TourActionHandler(tourManager: tourManager, buttonId: buttonId))
    }
}

// MARK: - Preview
struct GuidedTourOverlay_Previews: PreviewProvider {
    static var previews: some View {
        GuidedTourOverlay(tourManager: GuidedTourManager())
    }
}
