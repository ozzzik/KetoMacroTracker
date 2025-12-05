import SwiftUI

struct TutorialSettingsView: View {
    @ObservedObject var tutorialManager: TutorialManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Tutorial Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("Manage your tutorial experience")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Tutorial Status Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: tutorialManager.hasCompletedTutorial ? "checkmark.circle.fill" : "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(tutorialManager.hasCompletedTutorial ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tutorial Status")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(tutorialManager.hasCompletedTutorial ? "Completed" : "Not completed")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    Text(tutorialManager.hasCompletedTutorial ? 
                         "You've completed the tutorial and learned about macros, units, and app features." : 
                         "The tutorial will help you understand how to use the app effectively.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Watch Tutorial Button
                    Button(action: {
                        tutorialManager.showTutorial()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                            Text("Watch Tutorial")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    // Reset Tutorial Button
                    if tutorialManager.hasCompletedTutorial {
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 20))
                                Text("Reset Tutorial")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About the Tutorial")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TutorialInfoRow(
                            icon: "chart.bar.fill",
                            title: "Macro Calculations",
                            description: "Learn how your personalized macros are calculated"
                        )
                        
                        TutorialInfoRow(
                            icon: "scalemass.fill",
                            title: "Units & Measurements",
                            description: "Understand different units and conversions"
                        )
                        
                        TutorialInfoRow(
                            icon: "function",
                            title: "Net Carbs Formula",
                            description: "Master the net carbs calculation"
                        )
                        
                        TutorialInfoRow(
                            icon: "list.bullet.rectangle.fill",
                            title: "App Features",
                            description: "Discover all the tools available to you"
                        )
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Reset Tutorial", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                tutorialManager.resetTutorial()
            }
        } message: {
            Text("This will reset the tutorial completion status. The tutorial will show again on next app launch.")
        }
    }
}

// MARK: - Tutorial Info Row
struct TutorialInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct TutorialSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialSettingsView(tutorialManager: TutorialManager())
    }
}
