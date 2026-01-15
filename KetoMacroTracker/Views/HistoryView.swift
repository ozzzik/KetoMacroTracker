//
//  HistoryView.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @EnvironmentObject var foodLogManager: FoodLogManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    private var historicalDataManager: HistoricalDataManager {
        foodLogManager.getHistoricalDataManager()
    }
    
    private var isPremium: Bool {
        subscriptionManager.isPremiumActive
    }
    
    private var selectedDateSummary: DailySummary? {
        let summary = historicalDataManager.getSummaryForDate(selectedDate)
        print("🔍 HistoryView Debug - Selected date: \(selectedDate)")
        print("🔍 HistoryView Debug - Selected summary: \(summary?.netCarbs ?? 0)g net carbs")
        return summary
    }
    
    private var weeklyData: [DailySummary] {
        let data = historicalDataManager.getWeeklyData(for: selectedDate)
        // Apply premium limit
        return historicalDataManager.getHistoricalData(days: 7, isPremium: isPremium)
            .filter { summary in
                data.contains { $0.id == summary.id }
            }
    }
    
    private var monthlyData: [DailySummary] {
        let data = historicalDataManager.getMonthlyData(for: selectedDate)
        // Apply premium limit
        return historicalDataManager.getHistoricalData(days: 30, isPremium: isPremium)
            .filter { summary in
                data.contains { $0.id == summary.id }
            }
    }
    
    private var averageMacros: (protein: Double, netCarbs: Double, fat: Double, calories: Double) {
        let limitedData = historicalDataManager.getHistoricalData(days: 7, isPremium: isPremium)
        if limitedData.isEmpty {
            return (0, 0, 0, 0)
        }
        let totalProtein = limitedData.reduce(0) { $0 + $1.totalProtein }
        let totalNetCarbs = limitedData.reduce(0) { $0 + $1.netCarbs }
        let totalFat = limitedData.reduce(0) { $0 + $1.totalFat }
        let totalCalories = limitedData.reduce(0) { $0 + $1.totalCalories }
        let count = Double(limitedData.count)
        return (
            protein: totalProtein / count,
            netCarbs: totalNetCarbs / count,
            fat: totalFat / count,
            calories: totalCalories / count
        )
    }
    
    private var streakDays: Int {
        historicalDataManager.getStreakDays()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    HStack {
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(DateFormatter.shortDate.string(from: selectedDate))
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDate = Date()
                        }) {
                            Text("Today")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected Date Summary
                    if let summary = selectedDateSummary {
                        AppCard {
                            VStack(spacing: 16) {
                                Text("Daily Summary")
                                    .font(AppTypography.title3)
                                    .foregroundColor(AppColors.text)
                                
                                VStack(spacing: 12) {
                                    DailySummaryRow(
                                        title: "Net Carbs",
                                        value: "\(String(format: "%.1f", summary.netCarbs))g",
                                        color: AppColors.carbs
                                    )
                                    
                                    DailySummaryRow(
                                        title: "Protein",
                                        value: "\(String(format: "%.1f", summary.totalProtein))g",
                                        color: AppColors.protein
                                    )
                                    
                                    DailySummaryRow(
                                        title: "Fat",
                                        value: "\(String(format: "%.1f", summary.totalFat))g",
                                        color: AppColors.fat
                                    )
                                    
                                    DailySummaryRow(
                                        title: "Calories",
                                        value: "\(String(format: "%.0f", summary.totalCalories)) kcal",
                                        color: AppColors.calories
                                    )
                                }
                                
                                Text("\(summary.foodCount) food items logged")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    } else {
                        AppCard {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.minus")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("No food logged for this date")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                    
                    // Statistics Section
                    if !weeklyData.isEmpty {
                        VStack(spacing: 16) {
                            Text("Statistics")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                                .padding(.top)
                            
                            // Streak and Averages
                            AppCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Current Streak")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                            Text("\(streakDays) days")
                                                .font(AppTypography.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("7-Day Average")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                            Text("\(String(format: "%.0f", averageMacros.calories)) cal")
                                                .font(AppTypography.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(AppColors.calories)
                                        }
                                    }
                                }
                            }
                            
                            // Weekly Charts
                            Text("Weekly Trends")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            // Net Carbs Chart
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Net Carbs (g)")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.carbs)
                                    
                                    Chart(weeklyData) { data in
                                        BarMark(
                                            x: .value("Date", data.date, unit: .day),
                                            y: .value("Net Carbs", data.netCarbs)
                                        )
                                        .foregroundStyle(AppColors.carbs)
                                    }
                                    .frame(height: 150)
                                }
                            }
                            
                            // Protein Chart
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Protein (g)")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.protein)
                                    
                                    Chart(weeklyData) { data in
                                        LineMark(
                                            x: .value("Date", data.date, unit: .day),
                                            y: .value("Protein", data.totalProtein)
                                        )
                                        .foregroundStyle(AppColors.protein)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        PointMark(
                                            x: .value("Date", data.date, unit: .day),
                                            y: .value("Protein", data.totalProtein)
                                        )
                                        .foregroundStyle(AppColors.protein)
                                        .symbolSize(50)
                                    }
                                    .frame(height: 150)
                                }
                            }
                            
                            // Calories Chart
                            AppCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Calories (kcal)")
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.calories)
                                    
                                    Chart(weeklyData) { data in
                                        AreaMark(
                                            x: .value("Date", data.date, unit: .day),
                                            y: .value("Calories", data.totalCalories)
                                        )
                                        .foregroundStyle(AppColors.calories.opacity(0.3))
                                        
                                        LineMark(
                                            x: .value("Date", data.date, unit: .day),
                                            y: .value("Calories", data.totalCalories)
                                        )
                                        .foregroundStyle(AppColors.calories)
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                    }
                                    .frame(height: 150)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .background(AppColors.background)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fix Data") {
                        historicalDataManager.removeDuplicateSummaries()
                        print("🔧 Manual cleanup triggered")
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                // Force cleanup of duplicates first
                historicalDataManager.removeDuplicateSummaries()
                print("🔍 HistoryView Debug - Cleaned up duplicate summaries")
                
                // Force archive today's data to ensure consistency
                historicalDataManager.archiveCurrentDay(foodLogManager.todaysFoods)
                print("🔍 HistoryView Debug - Force archived today's data")
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
    }
    
}


// MARK: - Helper Views
struct DailySummaryRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    HistoryView()
        .environmentObject(FoodLogManager.shared)
}