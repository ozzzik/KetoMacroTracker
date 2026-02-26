//
//  HeartHealthGoalsView.swift
//  Keto Macro Tracker
//
//  View for editing cholesterol and saturated fat goals
//

import SwiftUI

struct HeartHealthGoalsView: View {
    @ObservedObject var profileManager: ProfileManager
    let onDismiss: () -> Void
    
    @State private var cholesterolGoal: String
    @State private var saturatedFatGoal: String
    
    init(profileManager: ProfileManager, onDismiss: @escaping () -> Void) {
        self.profileManager = profileManager
        self.onDismiss = onDismiss
        
        // Initialize with current values or defaults
        let currentCholesterol = profileManager.profile.cholesterolGoal ?? 300.0
        let currentSaturatedFat = profileManager.profile.saturatedFatGoal ?? 20.0
        
        _cholesterolGoal = State(initialValue: String(format: "%.0f", currentCholesterol))
        _saturatedFatGoal = State(initialValue: String(format: "%.1f", currentSaturatedFat))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Info Card
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                
                                Text("Heart Health Goals")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                            }
                            
                            Text("Set your daily limits for cholesterol and saturated fat intake. These goals help you maintain heart health while following your keto diet.")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    // Cholesterol Goal
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Cholesterol Goal")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                Circle()
                                    .fill(AppColors.cholesterol)
                                    .frame(width: 12, height: 12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Daily Limit (mg)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                TextField("300", text: $cholesterolGoal)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .font(AppTypography.body)
                                
                                Text("Recommended: 300mg/day or less")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Saturated Fat Goal
                    AppCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Saturated Fat Goal")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                Circle()
                                    .fill(AppColors.saturatedFat)
                                    .frame(width: 12, height: 12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Daily Limit (g)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                TextField("20.0", text: $saturatedFatGoal)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .font(AppTypography.body)
                                
                                Text("Recommended: 20g/day or less (about 10% of calories)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Save Button
                    AppButton(action: {
                        saveGoals()
                    }) {
                        Text("Save Goals")
                            .font(AppTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .padding()
            }
            .navigationTitle("Heart Health Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func saveGoals() {
        // Parse and validate cholesterol goal
        if let cholesterolValue = Double(cholesterolGoal), cholesterolValue > 0 {
            profileManager.updateCholesterolGoal(cholesterolValue)
        } else {
            // Reset to default if invalid
            profileManager.updateCholesterolGoal(300.0)
        }
        
        // Parse and validate saturated fat goal
        if let saturatedFatValue = Double(saturatedFatGoal), saturatedFatValue > 0 {
            profileManager.updateSaturatedFatGoal(saturatedFatValue)
        } else {
            // Reset to default if invalid
            profileManager.updateSaturatedFatGoal(20.0)
        }
        
        onDismiss()
    }
}

// MARK: - Preview
#Preview {
    HeartHealthGoalsView(profileManager: ProfileManager.shared) {
        // Dismiss handler
    }
}
