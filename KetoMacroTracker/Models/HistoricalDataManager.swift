//
//  HistoricalDataManager.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/28/25.
//

import Foundation
import SwiftUI

// MARK: - Daily Summary Model
struct DailySummary: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let foods: [LoggedFood]
    
    // Computed totals for the day
    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFat: Double {
        foods.reduce(0) { $0 + $1.totalFat }
    }
    
    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.totalCalories }
    }
    
    var netCarbs: Double {
        foods.reduce(0) { $0 + $1.netCarbs }
    }
    
    var foodCount: Int {
        foods.count
    }
}

// MARK: - Historical Data Manager
class HistoricalDataManager: ObservableObject {
    static let shared = HistoricalDataManager()
    
    @Published var dailySummaries: [DailySummary] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let userDefaultsKey = "HistoricalData"
    
    private init() {
        loadHistoricalData()
        removeDuplicateSummaries() // Clean up any existing duplicates
        checkForDayTransition()
    }
    
    // MARK: - Day Transition Logic
    func checkForDayTransition() {
        let today = Date()
        let todayString = dateFormatter.string(from: today)
        
        // Check if we have any pending data from previous days
        if let lastSavedDate = UserDefaults.standard.string(forKey: "LastSavedDate"),
           lastSavedDate != todayString {
            
            print("📅 Day transition detected: \(lastSavedDate) → \(todayString)")
            
            // Archive any pending data from the previous day
            archivePreviousDayData(from: lastSavedDate)
        }
        
        // Update the last saved date
        UserDefaults.standard.set(todayString, forKey: "LastSavedDate")
    }
    
    private func archivePreviousDayData(from dateString: String) {
        // Get any food data that might still be in UserDefaults from the previous day
        if let data = UserDefaults.standard.data(forKey: "FoodLogData"),
           let decodedFoods = try? JSONDecoder().decode([LoggedFood].self, from: data) {
            
            // Filter foods from the previous day
            let previousDayFoods = decodedFoods.filter { 
                dateFormatter.string(from: $0.dateAdded) == dateString 
            }
            
            if !previousDayFoods.isEmpty {
                // Create a daily summary for the previous day
                let dailySummary = DailySummary(
                    date: dateFormatter.date(from: dateString) ?? Date(),
                    foods: previousDayFoods
                )
                
                // Add to historical data
                dailySummaries.append(dailySummary)
                saveHistoricalData()
                
                print("📦 Archived \(previousDayFoods.count) food items from \(dateString)")
                print("📊 Daily totals - Protein: \(String(format: "%.1f", dailySummary.totalProtein))g, Net Carbs: \(String(format: "%.1f", dailySummary.netCarbs))g, Calories: \(String(format: "%.0f", dailySummary.totalCalories))")
            }
        }
    }
    
    // MARK: - Archive Current Day
    func archiveCurrentDay(_ foods: [LoggedFood]) {
        let today = Date()
        let todayString = dateFormatter.string(from: today)
        
        // Filter to only today's foods
        let todaysFoods = foods.filter { 
            dateFormatter.string(from: $0.dateAdded) == todayString 
        }
        
        if !todaysFoods.isEmpty {
            // Remove ALL existing summaries for today to prevent duplicates
            dailySummaries.removeAll { 
                dateFormatter.string(from: $0.date) == todayString 
            }
            
            // Create single summary for today
            let dailySummary = DailySummary(
                date: today,
                foods: todaysFoods
            )
            dailySummaries.append(dailySummary)
            
            // Sort by date (newest first)
            dailySummaries.sort { $0.date > $1.date }
            
            print("📦 Archived \(todaysFoods.count) foods for \(todayString) - Net carbs: \(String(format: "%.1f", dailySummary.netCarbs))g")
            
            saveHistoricalData()
        }
    }
    
    // MARK: - Data Retrieval
    func getSummaryForDate(_ date: Date) -> DailySummary? {
        let dateString = dateFormatter.string(from: date)
        return dailySummaries.first { 
            dateFormatter.string(from: $0.date) == dateString 
        }
    }
    
    func getSummariesForDateRange(from startDate: Date, to endDate: Date) -> [DailySummary] {
        return dailySummaries.filter { summary in
            summary.date >= startDate && summary.date <= endDate
        }.sorted { $0.date > $1.date }
    }
    
    func getWeeklyData(for date: Date) -> [DailySummary] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date
        
        return getSummariesForDateRange(from: weekStart, to: weekEnd)
    }
    
    func getMonthlyData(for date: Date) -> [DailySummary] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
        
        return getSummariesForDateRange(from: monthStart, to: monthEnd)
    }
    
    // MARK: - Recent Foods
    func getRecentFoods(days: Int = 7, limit: Int = 20) -> [LoggedFood] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentSummaries = dailySummaries.filter { $0.date >= cutoffDate }
        
        // Get all foods from recent summaries, sorted by most recent
        var recentFoods: [LoggedFood] = []
        for summary in recentSummaries.sorted(by: { $0.date > $1.date }) {
            recentFoods.append(contentsOf: summary.foods)
        }
        
        // Remove duplicates (same food name), keeping most recent
        var uniqueFoods: [String: LoggedFood] = [:]
        for food in recentFoods {
            let key = food.food.description.lowercased()
            if let existing = uniqueFoods[key] {
                // Keep the more recent one
                if food.dateAdded > existing.dateAdded {
                    uniqueFoods[key] = food
                }
            } else {
                uniqueFoods[key] = food
            }
        }
        
        // Return sorted by most recent, limited to requested count
        return Array(uniqueFoods.values)
            .sorted { $0.dateAdded > $1.dateAdded }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Statistics
    func getAverageDailyMacros(days: Int = 7) -> (protein: Double, netCarbs: Double, fat: Double, calories: Double) {
        let recentSummaries = dailySummaries.suffix(days)
        
        if recentSummaries.isEmpty {
            return (0, 0, 0, 0)
        }
        
        let totalProtein = recentSummaries.reduce(0) { $0 + $1.totalProtein }
        let totalNetCarbs = recentSummaries.reduce(0) { $0 + $1.netCarbs }
        let totalFat = recentSummaries.reduce(0) { $0 + $1.totalFat }
        let totalCalories = recentSummaries.reduce(0) { $0 + $1.totalCalories }
        
        let count = Double(recentSummaries.count)
        
        return (
            protein: totalProtein / count,
            netCarbs: totalNetCarbs / count,
            fat: totalFat / count,
            calories: totalCalories / count
        )
    }
    
    func getStreakDays() -> Int {
        let calendar = Calendar.current
        let sortedSummaries = dailySummaries.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = Date()
        
        for summary in sortedSummaries {
            if calendar.isDate(summary.date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Persistence
    private func saveHistoricalData() {
        if let encoded = try? JSONEncoder().encode(dailySummaries) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved \(dailySummaries.count) daily summaries to historical data")
        }
    }
    
    private func loadHistoricalData() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decodedSummaries = try? JSONDecoder().decode([DailySummary].self, from: data) else {
            print("💾 No historical data found, starting fresh")
            return
        }
        
        // Sort by date (newest first)
        dailySummaries = decodedSummaries.sorted { $0.date > $1.date }
        print("💾 Loaded \(dailySummaries.count) daily summaries from historical data")
    }
    
    // MARK: - Data Management
    func clearAllHistoricalData() {
        dailySummaries.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "LastSavedDate")
        print("🗑️ Cleared all historical data")
    }
    
    func removeDuplicateSummaries() {
        let originalCount = dailySummaries.count
        print("🔧 Manual cleanup started - Original count: \(originalCount)")
        
        // Group by date and keep only the most recent summary for each day
        let groupedByDate = Dictionary(grouping: dailySummaries) { summary in
            dateFormatter.string(from: summary.date)
        }
        
        print("🔧 Grouped into \(groupedByDate.count) unique dates")
        
        var cleanedSummaries: [DailySummary] = []
        for (dateString, summaries) in groupedByDate {
            print("🔧 Date \(dateString): \(summaries.count) summaries")
            for (index, summary) in summaries.enumerated() {
                print("🔧   Summary \(index + 1): \(summary.netCarbs)g net carbs, \(summary.foods.count) foods")
            }
            
            // Keep the most recent summary for each date
            if let mostRecent = summaries.max(by: { $0.date < $1.date }) {
                cleanedSummaries.append(mostRecent)
                print("🔧   Kept most recent: \(mostRecent.netCarbs)g net carbs")
            }
        }
        
        dailySummaries = cleanedSummaries.sorted { $0.date > $1.date }
        
        let removedCount = originalCount - dailySummaries.count
        print("🔧 Cleanup complete - Removed \(removedCount) duplicates, \(dailySummaries.count) remaining")
        
        if removedCount > 0 {
            saveHistoricalData()
            print("🧹 Removed \(removedCount) duplicate daily summaries")
        }
    }
    
    func clearOldData(keepDays: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepDays, to: Date()) ?? Date()
        let oldCount = dailySummaries.count
        dailySummaries = dailySummaries.filter { $0.date >= cutoffDate }
        
        if dailySummaries.count != oldCount {
            saveHistoricalData()
            print("🗑️ Cleared \(oldCount - dailySummaries.count) old daily summaries (keeping last \(keepDays) days)")
        }
    }
}


