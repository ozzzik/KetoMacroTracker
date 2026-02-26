//
//  HealthIntegrationView.swift
//  Keto Macro Tracker
//
//  View for managing Apple Health integration
//

import SwiftUI

struct HealthIntegrationView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var foodLogManager = FoodLogManager.shared
    @StateObject private var waterManager = WaterIntakeManager.shared
    @StateObject private var fastingManager = FastingManager.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAuthorizationAlert = false
    @State private var autoSyncEnabled = UserDefaults.standard.bool(forKey: "HealthKitAutoSync")
    
    var body: some View {
        NavigationStack {
            Form {
                // HealthKit Header
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HealthKit Integration")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                                
                                Text("Sync nutrition data with Apple Health")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            // HealthKit badge
                            Text("HealthKit")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What This Integration Does:")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.text)
                            
                            Text("Sync your nutrition data between this app and Apple Health. Your data stays on your device and is never shared with third parties.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.bottom, 4)
                            
                            Text("This app uses HealthKit to:")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.text)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Read from Health:")
                                            .font(AppTypography.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.text)
                                        Text("Weight, body fat percentage, and lean body mass")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Write to Health:")
                                            .font(AppTypography.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(AppColors.text)
                                        Text("Dietary protein, carbohydrates, fat, calories, and water intake")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Authorization Status
                Section(header: Text("Authorization")) {
                    HStack {
                        Text("Health App Access")
                        
                        Spacer()
                        
                        if healthKitManager.isAuthorized {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Authorized")
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Not Authorized")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if !healthKitManager.isAuthorized {
                        Button("Authorize Health Access") {
                                healthKitManager.requestAuthorization()
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
                
                // Read from Health
                if healthKitManager.isAuthorized {
                    Section(header: Text("Read from Health")) {
                        if let weight = healthKitManager.lastWeight,
                           let date = healthKitManager.lastWeightDate {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Latest Weight")
                                        .font(AppTypography.body)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", weight)) lbs")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.primary)
                                }
                                
                                Text("From \(formatDate(date))")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Button("Sync to Profile") {
                                    healthKitManager.syncWeightToProfile()
                                }
                                .foregroundColor(AppColors.primary)
                            }
                        } else {
                            Text("No weight data found in Health app")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    // Write to Health
                    Section(header: Text("Write to Health")) {
                        Toggle("Auto-Sync Nutrition", isOn: $autoSyncEnabled)
                            .onChange(of: autoSyncEnabled) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "HealthKitAutoSync")
                                if newValue {
                                    syncTodayToHealth()
                                }
                            }
                        
                        Text("Automatically sync your daily nutrition data to Apple Health")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Button("Sync Today's Data Now") {
                            syncTodayToHealth()
                        }
                        .foregroundColor(AppColors.primary)
                    }
                    
                    // Manual Sync
                    Section(header: Text("Manual Sync")) {
                        Button("Sync All Nutrition Data") {
                            syncAllNutritionToHealth()
                        }
                        .foregroundColor(AppColors.primary)
                        
                        Text("Sync all historical nutrition data to Health app")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .navigationTitle("HealthKit Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if healthKitManager.isAuthorized {
                    healthKitManager.loadLatestWeight()
                }
            }
        }
    }
    
    private func syncTodayToHealth() {
        _ = calculateMacroGoals(profile: profileManager.profile)
        
        healthKitManager.saveNutritionToHealth(
            protein: foodLogManager.totalProtein,
            carbs: foodLogManager.netCarbs,
            fat: foodLogManager.totalFat,
            calories: foodLogManager.totalCalories
        )
        
        // Convert cups to fluid ounces for HealthKit (1 cup = 8 fl oz)
        let ounces = waterManager.todaysWaterIntake * 8.0
        healthKitManager.saveWaterToHealth(amount: ounces)
        
        // Note: Fasting is not a standard HealthKit category, so we don't sync it
    }
    
    private func syncAllNutritionToHealth() {
        let historicalDataManager = HistoricalDataManager.shared
        let summaries = historicalDataManager.dailySummaries
        
        for summary in summaries {
            healthKitManager.saveNutritionToHealth(
                protein: summary.totalProtein,
                carbs: summary.netCarbs,
                fat: summary.totalFat,
                calories: summary.totalCalories,
                date: summary.date
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    HealthIntegrationView()
}

