//
//  InsightsDebugView.swift
//  Keto Macro Tracker
//
//  Debug view to test insights data flow
//

import SwiftUI

struct InsightsDebugView: View {
    @EnvironmentObject var foodLogManager: FoodLogManager
    @StateObject private var trendManager = NetCarbTrendManager.shared
    @StateObject private var historicalManager = HistoricalDataManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Food Log Data
                    debugSection("Food Log Data") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Foods: \(foodLogManager.todaysFoods.count)")
                            Text("Net Carbs: \(String(format: "%.1f", foodLogManager.netCarbs))g")
                            Text("Total Carbs: \(String(format: "%.1f", foodLogManager.totalCarbs))g")
                            Text("Protein: \(String(format: "%.1f", foodLogManager.totalProtein))g")
                            Text("Fat: \(String(format: "%.1f", foodLogManager.totalFat))g")
                        }
                    }
                    
                    // Historical Data
                    debugSection("Historical Data") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Summaries: \(historicalManager.dailySummaries.count)")
                            if !historicalManager.dailySummaries.isEmpty {
                                ForEach(historicalManager.dailySummaries.prefix(3)) { summary in
                                    Text("\(summary.date.formatted(date: .abbreviated, time: .omitted)): \(String(format: "%.1f", summary.netCarbs))g net carbs")
                                }
                            }
                        }
                    }
                    
                    // Trend Data
                    debugSection("Trend Data") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trends: \(trendManager.trends.count)")
                            Text("Current Streak: \(trendManager.currentStreak)")
                            Text("Weekly Average: \(String(format: "%.1f", trendManager.weeklyAverage))g")
                            if !trendManager.trends.isEmpty {
                                ForEach(trendManager.trends.prefix(3)) { trend in
                                    Text("\(trend.date.formatted(date: .abbreviated, time: .omitted)): \(String(format: "%.1f", trend.netCarbs))g net carbs")
                                }
                            }
                        }
                    }
                    
                    // Actions
                    debugSection("Actions") {
                        VStack(spacing: 12) {
                            Button("Update Trends") {
                                trendManager.updateTrends()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Archive Today's Data") {
                                historicalManager.archiveCurrentDay(foodLogManager.todaysFoods)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Clear All Data") {
                                foodLogManager.clearAllData()
                                trendManager.trends.removeAll()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func debugSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            AppCard {
                content()
            }
        }
    }
}

#Preview {
    InsightsDebugView()
        .environmentObject(FoodLogManager.shared)
}






