//
//  DemoOverlayView.swift
//  Keto Macro Tracker
//
//  Overlay view for demo mode highlighting
//

import SwiftUI

struct DemoOverlayView: View {
    @ObservedObject var demoManager = DemoModeManager.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        if demoManager.isDemoActive {
            ZStack {
                // Dimmed background - allow touches to pass through
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: demoManager.showHighlight)
                    .allowsHitTesting(false)
                
                // Highlight overlay - allow touches to pass through
                if demoManager.showHighlight, let highlightId = demoManager.currentHighlight {
                    HighlightView(elementId: highlightId)
                        .allowsHitTesting(false)
                }
                
                // Demo message card - this should be interactive
                VStack {
                    Spacer()
                    
                    DemoMessageCard(
                        title: demoManager.currentStep?.title ?? "",
                        message: demoManager.demoMessage,
                        progress: demoManager.progress,
                        progressText: demoManager.progressText
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(true) // Allow interactions with the card
                }
            }
        }
    }
}

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
        // Approximate positions for common UI elements
        // These are estimates and may need adjustment based on actual layout
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let safeAreaTop = geometry.safeAreaInsets.top
        let safeAreaBottom = geometry.safeAreaInsets.bottom
        let tabBarHeight: CGFloat = 49 // Standard tab bar height
        let tabBarY = screenHeight - tabBarHeight - safeAreaBottom
        
        switch elementId {
        case "macro_rings":
            // Progress rings typically in upper-middle area
            return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 200, width: 280, height: 200)
            
        case "add_food_button":
            // Floating action button typically bottom-right, above tab bar
            return CGRect(x: screenWidth - 50, y: tabBarY - 80, width: 60, height: 60)
            
        case "search_bar":
            // Search bar at top
            return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 60, width: screenWidth - 32, height: 44)
            
        case "barcode_button":
            // Barcode button near search
            return CGRect(x: screenWidth - 80, y: safeAreaTop + 60, width: 50, height: 44)
            
        case "food_result":
            // Food list item - first item in list
            return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 200, width: screenWidth - 32, height: 80)
            
        case "serving_selector":
            // Serving size selector - larger highlight for emphasis, in middle of screen
            return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: screenWidth - 32, height: 250)
            
        case "add_button":
            // Add to Today button - near bottom of sheet
            return CGRect(x: screenWidth * 0.5, y: screenHeight - 150, width: screenWidth - 32, height: 50)
            
        case "quick_add_button":
            // Quick Add/Star button in food detail view
            return CGRect(x: screenWidth - 100, y: safeAreaTop + 150, width: 60, height: 60)
            
        case "quick_add_categories":
            // Category tabs/buttons in QuickAddView
            return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 120, width: screenWidth - 32, height: 50)
            
        case "category_filter":
            // Category filter
            return CGRect(x: screenWidth * 0.5, y: safeAreaTop + 180, width: screenWidth - 32, height: 50)
            
        case "insights_tab":
            // Tab bar - Insights tab (2nd tab, index 1)
            let tabWidth = screenWidth / 5
            return CGRect(x: tabWidth * 1.5, y: tabBarY, width: tabWidth, height: tabBarHeight)
            
        case "profile_tab":
            // Tab bar - Profile tab (5th tab, index 4)
            let tabWidth = screenWidth / 5
            return CGRect(x: tabWidth * 4.5, y: tabBarY, width: tabWidth, height: tabBarHeight)
            
        default:
            return CGRect(x: screenWidth * 0.5, y: screenHeight * 0.5, width: 200, height: 100)
        }
    }
}

struct DemoMessageCard: View {
    let title: String
    let message: String
    let progress: Double
    let progressText: String
    @ObservedObject private var demoManager = DemoModeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEMO MODE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    demoManager.stopDemo()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text(progressText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        if demoManager.isPaused {
                            demoManager.resumeDemo()
                        } else {
                            demoManager.pauseDemo()
                        }
                    }) {
                        Image(systemName: demoManager.isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    
                    Button(action: {
                        demoManager.stopDemo()
                    }) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    DemoOverlayView(selectedTab: .constant(0))
}

