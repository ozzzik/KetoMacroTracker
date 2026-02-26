//
//  PredictiveInsightsView.swift
//  Keto Macro Tracker
//
//  View for predictive insights and goal timeline predictions
//

import SwiftUI

struct PredictiveInsightsView: View {
    @StateObject private var predictiveManager = PredictiveInsightsManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var selectedGoal: GoalType = .weightLoss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    goalSelectorSection
                    if let prediction = predictiveManager.predictGoalTimeline(goalType: selectedGoal) {
                        predictionCard(prediction)
                    }
                }
                .padding()
            }
            .navigationTitle("Goal Predictions")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Goal Selector
    private var goalSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Goal")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Goal", selection: $selectedGoal) {
                if profileManager.profile.goal == "Lose Fat" {
                    Text("Weight Loss").tag(GoalType.weightLoss)
                } else if profileManager.profile.goal == "Gain Weight" {
                    Text("Weight Gain").tag(GoalType.weightGain)
                }
                Text("Macro Consistency").tag(GoalType.macroConsistency)
                Text("Ketosis Maintenance").tag(GoalType.ketosisMaintenance)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Prediction Card
    private func predictionCard(_ prediction: GoalPrediction) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goalTitle(prediction.goalType))
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        if prediction.confidence > 0 {
                            HStack {
                                Text("Confidence: \(String(format: "%.0f", prediction.confidence * 100))%")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                ProgressView(value: prediction.confidence)
                                    .tint(confidenceColor(prediction.confidence))
                                    .frame(width: 100)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Current vs Target
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(formatValue(prediction.currentValue, type: prediction.goalType))
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                            .fontWeight(.bold)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(AppColors.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(formatValue(prediction.targetValue, type: prediction.goalType))
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                }
                
                // Timeline prediction
                if let weeks = prediction.predictedWeeks, weeks > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppColors.primary)
                            
                            Text("Predicted Timeline")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                        }
                        
                        Text("\(String(format: "%.0f", weeks)) weeks")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.primary)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Message
                Text(prediction.message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(8)
                
                // Recommendations
                if !prediction.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.text)
                        
                        ForEach(prediction.recommendations.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                    .padding(.top, 4)
                                
                                Text(prediction.recommendations[index])
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func goalTitle(_ type: GoalType) -> String {
        switch type {
        case .weightLoss: return "Weight Loss Goal"
        case .weightGain: return "Weight Gain Goal"
        case .macroConsistency: return "Macro Consistency"
        case .ketosisMaintenance: return "Ketosis Maintenance"
        }
    }
    
    private func formatValue(_ value: Double, type: GoalType) -> String {
        switch type {
        case .weightLoss, .weightGain:
            return "\(String(format: "%.1f", value)) lbs"
        case .macroConsistency, .ketosisMaintenance:
            return "\(String(format: "%.0f", value * 100))%"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.4 { return .orange }
        return .red
    }
}

#Preview {
    PredictiveInsightsView()
}

