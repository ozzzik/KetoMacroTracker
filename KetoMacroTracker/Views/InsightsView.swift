//
//  InsightsView.swift
//  Keto Macro Tracker
//
//  Main insights view with keto-specific analytics
//

import SwiftUI

struct InsightsView: View {
    @StateObject private var trendManager = NetCarbTrendManager.shared
    @StateObject private var profileManager = ProfileManager.shared
    @EnvironmentObject var foodLogManager: FoodLogManager
    
    @State private var selectedInsight: InsightType = .trends
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with current status
                    currentStatusCard
                    
                    // Insight type selector
                    insightTypeSelector
                    
                    // Selected insight content
                    selectedInsightContent
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Keto Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Force update trends when view appears
                trendManager.updateTrends()
            }
            .onChange(of: foodLogManager.todaysFoods.count) {
                // Update trends when food log changes
                trendManager.updateTrends()
            }
        }
    }
    
    // MARK: - Current Status Card
    private var currentStatusCard: some View {
        AppCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Today's Status")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    // Ketosis status indicator
                    ketosisStatusIndicator
                }
                
                // Today's macros vs goals
                todayMacrosCard
                
                // Quick insights
                quickInsightsRow
            }
        }
    }
    
    // MARK: - Ketosis Status Indicator
    private var ketosisStatusIndicator: some View {
        let status = trendManager.getCurrentKetosisStatus()
        
        return HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            Text(status.rawValue)
                .font(AppTypography.caption)
                .foregroundColor(status.color)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Today's Macros Card
    private var todayMacrosCard: some View {
        let todayCarbs = foodLogManager.netCarbs
        let goalCarbs = 20.0 // Standard keto limit
        let progress = min(todayCarbs / goalCarbs, 1.0)
        
        // Debug logging
        print("🔍 Insights Debug - Today's net carbs: \(todayCarbs)g, Foods logged: \(foodLogManager.todaysFoods.count)")
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Carbs")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Text("\(String(format: "%.1f", todayCarbs))g")
                    .font(AppTypography.title2)
                    .foregroundColor(todayCarbs < goalCarbs ? .green : .red)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Goal")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Text("\(Int(goalCarbs))g")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                    .fontWeight(.bold)
            }
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(todayCarbs < goalCarbs ? .green : .red, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(AppTypography.caption)
                    .foregroundColor(todayCarbs < goalCarbs ? .green : .red)
                    .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - Quick Insights Row
    private var quickInsightsRow: some View {
        HStack(spacing: 20) {
            quickInsightItem(
                title: "Streak",
                value: "\(trendManager.currentStreak)",
                subtitle: "days",
                color: .green
            )
            
            quickInsightItem(
                title: "Weekly Avg",
                value: String(format: "%.1f", trendManager.weeklyAverage),
                subtitle: "g carbs",
                color: trendManager.weeklyAverage < 20 ? .green : .orange
            )
            
            quickInsightItem(
                title: "Consistency",
                value: "\(Int(calculateConsistency() * 100))",
                subtitle: "%",
                color: calculateConsistency() > 0.8 ? .green : .orange
            )
        }
    }
    
    private func quickInsightItem(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Insight Type Selector
    private var insightTypeSelector: some View {
        Picker("Insight Type", selection: $selectedInsight) {
            Text("Trends").tag(InsightType.trends)
            Text("Balance").tag(InsightType.balance)
            Text("Ketosis").tag(InsightType.ketosis)
            Text("Analytics").tag(InsightType.analytics)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    // MARK: - Selected Insight Content
    @ViewBuilder
    private var selectedInsightContent: some View {
        switch selectedInsight {
        case .trends:
            trendsContent
        case .balance:
            balanceContent
        case .ketosis:
            ketosisContent
        case .analytics:
            VStack(spacing: 20) {
                AnalyticsView()
                    .padding(.horizontal, -16) // Remove double padding
                
                // Predictive Insights
                NavigationLink(destination: PredictiveInsightsView()) {
                    AppCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal Predictions")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                Text("See when you'll reach your goals")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Trends Content
    private var trendsContent: some View {
        let weeklySummaries = trendManager.getWeeklySummaries(limit: 4)
        return VStack(spacing: 16) {
            if trendManager.trends.isEmpty {
                emptyDataCard
            } else {
                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Net Carb Trends")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        NetCarbTrendChart()
                    }
                }
                
                // Additional trend insights
                if !weeklySummaries.isEmpty {
                    WeeklyTrendSummaryView(
                        summaries: weeklySummaries,
                        weekDelta: trendManager.weekOverWeekDelta()
                    )
                }
                
                trendInsightsCard
            }
        }
    }
    
    // MARK: - Empty Data Card
    private var emptyDataCard: some View {
        AppCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.secondaryText)
                
                Text("No Data Yet")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text("Start logging your food to see insights and trends. Your keto journey begins with the first meal!")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button("Go to Today") {
                    // This would navigate to the Today tab
                    // For now, just show the message
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Trend Insights Card
    private var trendInsightsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Trend Analysis")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                let insights = generateTrendInsights()
                
                ForEach(insights, id: \.self) { insight in
                    HStack {
                        Image(systemName: insight.icon)
                            .foregroundColor(insight.color)
                            .font(.caption)
                        
                        Text(insight.text)
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Balance Content
    private var balanceContent: some View {
        let profile = profileManager.profile
        let goals = calculateMacroGoals(profile: profile)
        let currentProtein = foodLogManager.totalProtein
        let currentCarbs = foodLogManager.netCarbs
        let currentFat = foodLogManager.totalFat
        let currentCalories = foodLogManager.totalCalories
        
        // Calculate percentages
        let proteinCalories = currentProtein * 4
        let carbCalories = currentCarbs * 4
        let fatCalories = currentFat * 9
        let totalCalories = max(currentCalories, 1.0) // Avoid division by zero
        
        let proteinPercentage = (proteinCalories / totalCalories) * 100
        let carbPercentage = (carbCalories / totalCalories) * 100
        let fatPercentage = (fatCalories / totalCalories) * 100
        
        // Calculate ratios (in calories, not grams)
        // Fat:Protein ratio should be calculated from calories: fatCalories / proteinCalories
        let fatToProteinRatio = proteinCalories > 0 ? fatCalories / proteinCalories : 0
        
        // Ideal ranges for keto
        let idealProteinRange = (20.0...35.0) // 20-35% of calories
        let idealFatRange = (60.0...75.0) // 60-75% of calories
        let idealCarbRange = (0.0...10.0) // 0-10% of calories
        let idealFatProteinRatio = 1.5...2.5 // Fat should be 1.5-2.5x protein
        
        return VStack(spacing: 16) {
            // Current Macro Percentages
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's Macro Balance")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    // Protein
                    macroBalanceRow(
                        label: "Protein",
                        percentage: proteinPercentage,
                        idealRange: idealProteinRange,
                        color: AppColors.protein
                    )
                    
                    // Carbs
                    macroBalanceRow(
                        label: "Net Carbs",
                        percentage: carbPercentage,
                        idealRange: idealCarbRange,
                        color: AppColors.carbs
                    )
                    
                    // Fat
                    macroBalanceRow(
                        label: "Fat",
                        percentage: fatPercentage,
                        idealRange: idealFatRange,
                        color: AppColors.fat
                    )
                    
                    Divider()
                    
                    // Fat to Protein Ratio
                    HStack {
                        Text("Fat:Protein Ratio")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Text(String(format: "%.2f:1", fatToProteinRatio))
                            .font(AppTypography.headline)
                            .foregroundColor(idealFatProteinRatio.contains(fatToProteinRatio) ? .green : .orange)
                        
                        if !idealFatProteinRatio.contains(fatToProteinRatio) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Balance Warnings
            if let warnings = generateBalanceWarnings(
                proteinPercentage: proteinPercentage,
                fatPercentage: fatPercentage,
                carbPercentage: carbPercentage,
                fatToProteinRatio: fatToProteinRatio,
                currentCarbs: currentCarbs,
                carbGoal: goals.carbs
            ), !warnings.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Balance Warnings")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        ForEach(warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .padding(.top, 4)
                                
                                Text(warning)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                    }
                }
            }
            
            // Ideal Keto Ratios Info
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ideal Keto Ratios")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        idealRatioRow("Fat", "60-75% of calories")
                        idealRatioRow("Protein", "20-35% of calories")
                        idealRatioRow("Net Carbs", "0-10% of calories")
                        idealRatioRow("Fat:Protein", "1.5:1 to 2.5:1")
                    }
                }
            }
        }
    }
    
    private func macroBalanceRow(label: String, percentage: Double, idealRange: ClosedRange<Double>, color: Color) -> some View {
        let isIdeal = idealRange.contains(percentage)
        
        return HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: percentage / 100.0)
                    .tint(isIdeal ? color : .orange)
                    .frame(width: 100)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(AppTypography.caption)
                    .foregroundColor(isIdeal ? color : .orange)
                    .frame(width: 50, alignment: .trailing)
                
                if isIdeal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
    }
    
    private func idealRatioRow(_ label: String, _ range: String) -> some View {
        HStack {
            Text("• \(label):")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.text)
            
            Text(range)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private func generateBalanceWarnings(
        proteinPercentage: Double,
        fatPercentage: Double,
        carbPercentage: Double,
        fatToProteinRatio: Double,
        currentCarbs: Double,
        carbGoal: Double
    ) -> [String]? {
        var warnings: [String] = []
        
        if proteinPercentage > 35 {
            warnings.append("Too much protein (\(String(format: "%.1f", proteinPercentage))%). Aim for 20-35% to maintain ketosis.")
        }
        
        if fatPercentage < 60 {
            warnings.append("Not enough fat (\(String(format: "%.1f", fatPercentage))%). Increase fat intake to 60-75% of calories.")
        }
        
        if fatToProteinRatio < 1.5 {
            warnings.append("Fat:Protein ratio too low (\(String(format: "%.2f", fatToProteinRatio)):1). Increase fat or reduce protein.")
        }
        
        if currentCarbs > carbGoal * 0.8 {
            warnings.append("Approaching carb limit (\(String(format: "%.1f", currentCarbs))g / \(String(format: "%.0f", carbGoal))g).")
        }
        
        return warnings.isEmpty ? nil : warnings
    }
    
    // MARK: - Ketosis Content
    private var ketosisContent: some View {
        let currentStatus = trendManager.getCurrentKetosisStatus()
        let currentTrend = trendManager.trends.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: Date()) 
        })
        let recentTrends = trendManager.getTrends(for: .week)
        let ketoDays = recentTrends.filter { $0.isKetoFriendly }.count
        let weeklyConsistency = recentTrends.isEmpty ? 0.0 : Double(ketoDays) / Double(recentTrends.count) * 100
        let currentStreak = trendManager.currentStreak
        
        return VStack(spacing: 16) {
            // Current Status
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Current Ketosis Status")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentStatus.color)
                                .frame(width: 16, height: 16)
                            
                            Text(currentStatus.rawValue)
                                .font(AppTypography.headline)
                                .foregroundColor(currentStatus.color)
                        }
                    }
                    
                    if let trend = currentTrend {
                        Text(currentStatus.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Net Carbs")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("\(String(format: "%.1f", trend.netCarbs))g")
                                    .font(AppTypography.title3)
                                    .foregroundColor(trend.isKetoFriendly ? .green : .red)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Ketosis Probability")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("\(String(format: "%.0f", trend.ketosisProbability * 100))%")
                                    .font(AppTypography.title3)
                                    .foregroundColor(ketosisProbabilityColor(trend.ketosisProbability))
                                    .fontWeight(.bold)
                            }
                        }
                    } else {
                        Text("No data for today yet. Log your meals to see your ketosis status.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            
            // Streak & Consistency
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Consistency Metrics")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            HStack(spacing: 4) {
                                Text("\(currentStreak)")
                                    .font(AppTypography.title2)
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                                
                                Text("days")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Weekly Consistency")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            HStack(spacing: 4) {
                                Text("\(String(format: "%.0f", weeklyConsistency))%")
                                    .font(AppTypography.title2)
                                    .foregroundColor(weeklyConsistency >= 80 ? .green : weeklyConsistency >= 60 ? .orange : .red)
                                    .fontWeight(.bold)
                                
                                Text("(\(ketoDays)/\(recentTrends.count))")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                }
            }
            
            // Ketosis Levels Guide
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ketosis Levels")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    ForEach(KetosisStatus.allCases, id: \.self) { status in
                        HStack {
                            Circle()
                                .fill(status.color)
                                .frame(width: 12, height: 12)
                            
                            Text(status.rawValue)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            Text(ketosisRange(for: status))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
        }
    }
    
    private func ketosisProbabilityColor(_ probability: Double) -> Color {
        if probability >= 0.8 { return .green }
        if probability >= 0.5 { return .orange }
        return .red
    }
    
    private func ketosisRange(for status: KetosisStatus) -> String {
        switch status {
        case .optimal: return "0-10g"
        case .good: return "10-20g"
        case .borderline: return "20-30g"
        case .unlikely: return "30-50g"
        case .out: return "50g+"
        }
    }
    
    // MARK: - Helper Functions
    private func calculateConsistency() -> Double {
        let recentTrends = trendManager.getTrends(for: .week)
        let ketoDays = recentTrends.filter { $0.isKetoFriendly }.count
        return recentTrends.isEmpty ? 0.0 : Double(ketoDays) / Double(recentTrends.count)
    }
    
    private func generateTrendInsights() -> [TrendInsight] {
        var insights: [TrendInsight] = []
        
        let recentTrends = trendManager.getTrends(for: .week)
        let ketoDays = recentTrends.filter { $0.isKetoFriendly }.count
        
        if ketoDays == recentTrends.count {
            insights.append(TrendInsight(
                text: "Perfect week! You stayed under 20g every day.",
                icon: "checkmark.circle.fill",
                color: .green
            ))
        } else if ketoDays >= Int(Double(recentTrends.count) * 0.8) {
            insights.append(TrendInsight(
                text: "Great consistency! You're mostly staying keto-friendly.",
                icon: "star.fill",
                color: .green
            ))
        } else if ketoDays >= Int(Double(recentTrends.count) * 0.6) {
            insights.append(TrendInsight(
                text: "Good progress! Try to stay under 20g more consistently.",
                icon: "arrow.up.circle.fill",
                color: .orange
            ))
        } else {
            insights.append(TrendInsight(
                text: "Focus on staying under 20g net carbs for better ketosis.",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        }
        
        if trendManager.currentStreak >= 7 {
            insights.append(TrendInsight(
                text: "Amazing streak! \(trendManager.currentStreak) days in a row!",
                icon: "flame.fill",
                color: .orange
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Types
enum InsightType {
    case trends, balance, ketosis, analytics
}

struct TrendInsight: Hashable {
    let text: String
    let icon: String
    let color: Color
}

// MARK: - Preview
#Preview {
    InsightsView()
        .environmentObject(FoodLogManager.shared)
}
