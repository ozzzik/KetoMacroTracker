import SwiftUI

struct TutorialView: View {
    @ObservedObject var tutorialManager: TutorialManager
    @Environment(\.dismiss) var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip Tutorial") {
                        tutorialManager.skipTutorial()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                
                // Tutorial content
                TabView(selection: $tutorialManager.currentSlideIndex) {
                    ForEach(Array(tutorialManager.tutorialSlides.enumerated()), id: \.element.id) { index, slide in
                        TutorialSlideView(
                            slide: slide,
                            isAnimating: isAnimating
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: tutorialManager.currentSlideIndex)
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<tutorialManager.tutorialSlides.count, id: \.self) { index in
                        Circle()
                            .fill(index == tutorialManager.currentSlideIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == tutorialManager.currentSlideIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: tutorialManager.currentSlideIndex)
                    }
                }
                .padding(.vertical, 20)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if tutorialManager.currentSlideIndex > 0 {
                        Button(action: {
                            tutorialManager.previousSlide()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(25)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if tutorialManager.currentSlideIndex == tutorialManager.tutorialSlides.count - 1 {
                            tutorialManager.skipTutorial()
                            dismiss()
                        } else {
                            tutorialManager.nextSlide()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(tutorialManager.currentSlideIndex == tutorialManager.tutorialSlides.count - 1 ? "Get Started" : "Next")
                            if tutorialManager.currentSlideIndex < tutorialManager.tutorialSlides.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Tutorial Slide View
struct TutorialSlideView: View {
    let slide: TutorialSlide
    let isAnimating: Bool
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon/Image
            if let imageName = slide.imageName {
                Image(systemName: imageName)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.1), value: isAnimating)
            }
            
            VStack(spacing: 16) {
                // Title
                Text(slide.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .offset(y: contentOffset)
                    .opacity(contentOpacity)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
                
                // Subtitle
                if let subtitle = slide.subtitle {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .offset(y: contentOffset)
                        .opacity(contentOpacity)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)
                }
            }
            
            // Content
            ScrollView {
                Text(slide.content)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
            }
            .frame(maxHeight: 200)
            .offset(y: contentOffset)
            .opacity(contentOpacity)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            if isAnimating {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    contentOffset = 0
                    contentOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Tutorial Slide Types
extension TutorialSlide {
    var backgroundColor: Color {
        switch slideType {
        case .welcome:
            return Color.blue.opacity(0.1)
        case .macroExplanation:
            return Color.green.opacity(0.1)
        case .unitsExplanation:
            return Color.orange.opacity(0.1)
        case .calculationExample:
            return Color.purple.opacity(0.1)
        case .featuresOverview:
            return Color.red.opacity(0.1)
        case .quickStart:
            return Color.indigo.opacity(0.1)
        }
    }
}

// MARK: - Preview
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView(tutorialManager: TutorialManager())
    }
}
