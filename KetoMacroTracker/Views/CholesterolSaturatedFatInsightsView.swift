//
//  CholesterolSaturatedFatInsightsView.swift
//  Keto Macro Tracker
//
//  View for cholesterol and saturated fat insights with LDL information
//

import SwiftUI

struct CholesterolSaturatedFatInsightsView: View {
    @EnvironmentObject var foodLogManager: FoodLogManager
    @StateObject private var profileManager = ProfileManager.shared
    
    private var cholesterolGoal: Double {
        profileManager.profile.cholesterolGoal ?? 300.0
    }
    
    private var saturatedFatGoal: Double {
        profileManager.profile.saturatedFatGoal ?? 20.0
    }
    
    private var currentCholesterol: Double {
        foodLogManager.totalCholesterol
    }
    
    private var currentSaturatedFat: Double {
        foodLogManager.totalSaturatedFat
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Status Card
                todayStatusCard
                
                // Cholesterol Card
                cholesterolCard
                
                // Saturated Fat Card
                saturatedFatCard
                
                // LDL Information Card
                ldlInfoCard
                
                // Recommendations Card
                recommendationsCard
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Today's Status Card
    private var todayStatusCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Heart Health")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cholesterol")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(currentCholesterol))")
                                .font(AppTypography.title2)
                                .foregroundColor(cholesterolColor)
                            
                            Text("mg")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Text("Goal: \(Int(cholesterolGoal))mg")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Divider()
                        .frame(height: 50)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saturated Fat")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(String(format: "%.1f", currentSaturatedFat))")
                                .font(AppTypography.title2)
                                .foregroundColor(saturatedFatColor)
                            
                            Text("g")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Text("Goal: \(String(format: "%.1f", saturatedFatGoal))g")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Cholesterol Card
    private var cholesterolCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Cholesterol")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Circle()
                        .fill(cholesterolColor)
                        .frame(width: 12, height: 12)
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(Int(currentCholesterol)) / \(Int(cholesterolGoal)) mg")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Text("\(Int((currentCholesterol / cholesterolGoal) * 100))%")
                            .font(AppTypography.callout)
                            .foregroundColor(cholesterolColor)
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.secondaryBackground)
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(cholesterolColor)
                                .frame(width: min(geometry.size.width * (currentCholesterol / cholesterolGoal), geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Status message
                Text(cholesterolStatusMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(cholesterolColor)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Saturated Fat Card
    private var saturatedFatCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Saturated Fat")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Circle()
                        .fill(saturatedFatColor)
                        .frame(width: 12, height: 12)
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(String(format: "%.1f", currentSaturatedFat)) / \(String(format: "%.1f", saturatedFatGoal)) g")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Text("\(Int((currentSaturatedFat / saturatedFatGoal) * 100))%")
                            .font(AppTypography.callout)
                            .foregroundColor(saturatedFatColor)
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.secondaryBackground)
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(saturatedFatColor)
                                .frame(width: min(geometry.size.width * (currentSaturatedFat / saturatedFatGoal), geometry.size.width), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Status message
                Text(saturatedFatStatusMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(saturatedFatColor)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - LDL Information Card
    private var ldlInfoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    Text("LDL Cholesterol Information")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Understanding LDL Cholesterol")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text("LDL (Low-Density Lipoprotein) is often called 'bad cholesterol' because high levels can lead to plaque buildup in arteries and increase heart disease risk.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended LDL Levels:")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.text)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ldlLevelRow(level: "Optimal", value: "< 100 mg/dL", color: .green)
                            ldlLevelRow(level: "Near/Above Optimal", value: "100-129 mg/dL", color: .yellow)
                            ldlLevelRow(level: "Borderline High", value: "130-159 mg/dL", color: .orange)
                            ldlLevelRow(level: "High", value: "160-189 mg/dL", color: .red)
                            ldlLevelRow(level: "Very High", value: "≥ 190 mg/dL", color: .red)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dietary Impact:")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.text)
                        
                        Text("• Dietary cholesterol intake (from food) has less impact on blood LDL than previously thought")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                        
                        Text("• Saturated fat intake has a more significant impact on LDL levels")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                        
                        Text("• Trans fats have the strongest negative impact on LDL")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
    
    private func ldlLevelRow(level: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(level)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    // MARK: - Recommendations Card
    private var recommendationsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heart Health Recommendations")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(alignment: .leading, spacing: 12) {
                    recommendationItem(
                        icon: "leaf.fill",
                        title: "Focus on Unsaturated Fats",
                        description: "Choose olive oil, avocados, nuts, and fatty fish over saturated fats when possible."
                    )
                    
                    recommendationItem(
                        icon: "fish.fill",
                        title: "Omega-3 Rich Foods",
                        description: "Include salmon, mackerel, and walnuts to support heart health."
                    )
                    
                    recommendationItem(
                        icon: "carrot.fill",
                        title: "Fiber-Rich Foods",
                        description: "Soluble fiber can help lower LDL cholesterol levels."
                    )
                    
                    recommendationItem(
                        icon: "figure.run",
                        title: "Regular Exercise",
                        description: "Physical activity can help improve cholesterol levels and overall heart health."
                    )
                    
                    recommendationItem(
                        icon: "exclamationmark.triangle.fill",
                        title: "Limit Trans Fats",
                        description: "Avoid processed foods with partially hydrogenated oils, which raise LDL significantly."
                    )
                }
            }
        }
    }
    
    private func recommendationItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var cholesterolColor: Color {
        let percentage = currentCholesterol / cholesterolGoal
        if percentage < 0.8 {
            return .green
        } else if percentage < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var saturatedFatColor: Color {
        let percentage = currentSaturatedFat / saturatedFatGoal
        if percentage < 0.8 {
            return .green
        } else if percentage < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var cholesterolStatusMessage: String {
        let percentage = currentCholesterol / cholesterolGoal
        if percentage < 0.8 {
            return "✓ Within recommended limit"
        } else if percentage < 1.0 {
            return "⚠ Approaching daily limit"
        } else {
            return "⚠ Exceeded daily limit"
        }
    }
    
    private var saturatedFatStatusMessage: String {
        let percentage = currentSaturatedFat / saturatedFatGoal
        if percentage < 0.8 {
            return "✓ Within recommended limit"
        } else if percentage < 1.0 {
            return "⚠ Approaching daily limit"
        } else {
            return "⚠ Exceeded daily limit"
        }
    }
}

// MARK: - Preview
#Preview {
    CholesterolSaturatedFatInsightsView()
        .environmentObject(FoodLogManager.shared)
}
