//
//  AnalyticsView.swift
//  Keto Macro Tracker
//
//  Advanced analytics and insights view
//

import SwiftUI

struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @StateObject private var historicalDataManager = HistoricalDataManager.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }
    
    private var availableTimeframes: [Timeframe] {
        Timeframe.allCases
    }
    
    private var days: Int {
        switch selectedTimeframe {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(availableTimeframes, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Macro Efficiency Score
                    efficiencyScoreSection
                    
                    // Correlation Analysis
                    correlationSection
                    
                    // Trend Analysis
                    trendSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Efficiency Score Section
    private var efficiencyScoreSection: some View {
        let efficiency = analyticsManager.calculateMacroEfficiency(days: days)
        
        return AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Macro Efficiency")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.0f", efficiency.overall))%")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(efficiencyColor(efficiency.overall))
                        .fontWeight(.bold)
                }
                
                Text(efficiency.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                
                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it's calculated:")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .fontWeight(.semibold)
                    
                    Text("• Protein: How close you are to your goal (capped at 100%)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("• Carbs: Lower is better - staying under your limit")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("• Fat: How close you are to your goal (capped at 100%)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("• Calories: How close you are to your goal (capped at 100%)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("• Overall: Weighted average (Protein 30%, Carbs 30%, Fat 20%, Calories 20%)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(AppColors.secondaryBackground)
                .cornerRadius(8)
                
                Divider()
                
                // Individual scores
                VStack(spacing: 12) {
                    efficiencyRow("Protein", score: efficiency.protein, color: AppColors.protein)
                    efficiencyRow("Carbs", score: efficiency.carbs, color: AppColors.carbs)
                    efficiencyRow("Fat", score: efficiency.fat, color: AppColors.fat)
                    efficiencyRow("Calories", score: efficiency.calories, color: AppColors.calories)
                    efficiencyRow("Consistency", score: efficiency.consistency, color: .purple)
                }
            }
        }
    }
    
    private func efficiencyRow(_ label: String, score: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            ProgressView(value: score / 100.0)
                .tint(color)
                .frame(width: 150)
            
            Text("\(String(format: "%.0f", score))%")
                .font(AppTypography.caption)
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private func efficiencyColor(_ score: Double) -> Color {
        if score >= 90 { return .green }
        if score >= 75 { return .blue }
        if score >= 60 { return .orange }
        return .red
    }
    
    // MARK: - Correlation Section
    private var correlationSection: some View {
        let correlations = analyticsManager.analyzeCorrelations(days: days)
        
        return AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Correlation Analysis")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if correlations.isEmpty {
                    Text("Not enough data for correlation analysis")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.vertical)
                } else {
                    ForEach(correlations.indices, id: \.self) { index in
                        let correlation = correlations[index]
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(correlation.metric1) ↔ \(correlation.metric2)")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text(correlation.strength.rawValue)
                                        .font(AppTypography.caption)
                                        .foregroundColor(strengthColor(correlation.strength))
                                    
                                    Text("(\(String(format: "%.2f", correlation.correlation)))")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                            
                            Text(correlation.description)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func strengthColor(_ strength: CorrelationStrength) -> Color {
        switch strength {
        case .strong: return .green
        case .moderate: return .blue
        case .weak: return .orange
        case .none: return .gray
        }
    }
    
    // MARK: - Trend Section
    private var trendSection: some View {
        let trends = analyticsManager.analyzeTrends(days: days)
        
        return AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trend Insights")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if trends.isEmpty {
                    Text("No significant trends detected")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.vertical)
                } else {
                    ForEach(trends.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            
                            Text(trends[index])
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
}

