//
//  DataExportManager.swift
//  Keto Macro Tracker
//
//  Manages data export to CSV format
//

import Foundation
import SwiftUI

// MARK: - Data Export Manager
class DataExportManager: ObservableObject {
    static let shared = DataExportManager()
    
    private let foodLogManager = FoodLogManager.shared
    private let historicalDataManager = HistoricalDataManager.shared
    private let waterManager = WaterIntakeManager.shared
    private let fastingManager = FastingManager.shared
    private let profileManager = ProfileManager.shared
    
    private init() {}
    
    // MARK: - CSV Export Methods
    
    func exportDailyData(days: Int = 30) -> String {
        var csv = "Date,Protein (g),Net Carbs (g),Fat (g),Calories,Water (oz),Fasting Duration (h)\n"
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let summaries = historicalDataManager.dailySummaries
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
        
        for summary in summaries {
            let dateString = formatDate(summary.date)
            let protein = String(format: "%.1f", summary.totalProtein)
            let carbs = String(format: "%.1f", summary.netCarbs)
            let fat = String(format: "%.1f", summary.totalFat)
            let calories = String(format: "%.0f", summary.totalCalories)
            
            // Get water intake for that day (would need to track historical water data)
            let water = "0" // Placeholder - would need historical water tracking
            
            // Get fasting duration for that day
            let fastingDuration = getFastingDurationForDate(summary.date)
            
            csv += "\(dateString),\(protein),\(carbs),\(fat),\(calories),\(water),\(fastingDuration)\n"
        }
        
        // Add today's data if not in summaries yet
        if !foodLogManager.todaysFoods.isEmpty {
            let today = Date()
            let dateString = formatDate(today)
            let protein = String(format: "%.1f", foodLogManager.totalProtein)
            let carbs = String(format: "%.1f", foodLogManager.netCarbs)
            let fat = String(format: "%.1f", foodLogManager.totalFat)
            let calories = String(format: "%.0f", foodLogManager.totalCalories)
            let water = String(format: "%.1f cups", waterManager.todaysWaterIntake)
            let fastingDuration = fastingManager.currentSession != nil ? 
                String(format: "%.2f", fastingManager.getCurrentDuration() / 3600) : "0"
            
            csv += "\(dateString),\(protein),\(carbs),\(fat),\(calories),\(water),\(fastingDuration)\n"
        }
        
        return csv
    }
    
    func exportFoodLog(days: Int = 30) -> String {
        var csv = "Date,Food Name,Servings,Protein (g),Carbs (g),Fat (g),Calories,Net Carbs (g)\n"
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let summaries = historicalDataManager.dailySummaries
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
        
        for summary in summaries {
            let dateString = formatDate(summary.date)
            
            for food in summary.foods {
                let foodName = escapeCSV(food.food.description)
                let servings = String(format: "%.2f", food.servings)
                let protein = String(format: "%.1f", food.totalProtein)
                let carbs = String(format: "%.1f", food.totalCarbs)
                let fat = String(format: "%.1f", food.totalFat)
                let calories = String(format: "%.0f", food.totalCalories)
                let netCarbs = String(format: "%.1f", food.netCarbs)
                
                csv += "\(dateString),\(foodName),\(servings),\(protein),\(carbs),\(fat),\(calories),\(netCarbs)\n"
            }
        }
        
        // Add today's foods
        let today = Date()
        let dateString = formatDate(today)
        
        for food in foodLogManager.todaysFoods {
            let foodName = escapeCSV(food.food.description)
            let servings = String(format: "%.2f", food.servings)
            let protein = String(format: "%.1f", food.totalProtein)
            let carbs = String(format: "%.1f", food.totalCarbs)
            let fat = String(format: "%.1f", food.totalFat)
            let calories = String(format: "%.0f", food.totalCalories)
            let netCarbs = String(format: "%.1f", food.netCarbs)
            
            csv += "\(dateString),\(foodName),\(servings),\(protein),\(carbs),\(fat),\(calories),\(netCarbs)\n"
        }
        
        return csv
    }
    
    func exportFastingHistory() -> String {
        var csv = "Start Date,End Date,Type,Duration (hours),Target Duration (hours)\n"
        
        for session in fastingManager.fastingHistory.sorted(by: { $0.startDate > $1.startDate }) {
            let startDate = formatDateTime(session.startDate)
            let endDate = session.endDate != nil ? formatDateTime(session.endDate!) : "Active"
            let type = session.type.displayName
            let duration = String(format: "%.2f", session.duration / 3600)
            let target = session.targetDuration != nil ? 
                String(format: "%.2f", session.targetDuration! / 3600) : ""
            
            csv += "\(startDate),\(endDate),\(type),\(duration),\(target)\n"
        }
        
        // Add current session if active
        if let session = fastingManager.currentSession {
            let startDate = formatDateTime(session.startDate)
            let endDate = "Active"
            let type = session.type.displayName
            let duration = String(format: "%.2f", session.duration / 3600)
            let target = session.targetDuration != nil ? 
                String(format: "%.2f", session.targetDuration! / 3600) : ""
            
            csv += "\(startDate),\(endDate),\(type),\(duration),\(target)\n"
        }
        
        return csv
    }
    
    func exportAllData() -> String {
        var csv = "=== KETO MACRO TRACKER DATA EXPORT ===\n"
        csv += "Export Date: \(formatDateTime(Date()))\n"
        csv += "Profile: \(profileManager.profile.weight) lbs, \(profileManager.profile.height) cm, \(profileManager.profile.age) years\n"
        csv += "\n"
        
        csv += "=== DAILY SUMMARY ===\n"
        csv += exportDailyData(days: 365)
        csv += "\n\n"
        
        csv += "=== FOOD LOG ===\n"
        csv += exportFoodLog(days: 365)
        csv += "\n\n"
        
        csv += "=== FASTING HISTORY ===\n"
        csv += exportFastingHistory()
        
        return csv
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func escapeCSV(_ text: String) -> String {
        // Escape quotes and wrap in quotes if contains comma or quote
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return text
    }
    
    private func getFastingDurationForDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let sessions = fastingManager.fastingHistory.filter { session in
            guard let endDate = session.endDate else { return false }
            return calendar.isDate(session.startDate, inSameDayAs: date) ||
                   calendar.isDate(endDate, inSameDayAs: date)
        }
        
        if let session = sessions.first {
            return String(format: "%.2f", session.duration / 3600)
        }
        return "0"
    }
}

