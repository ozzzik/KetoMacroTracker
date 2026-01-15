//
//  WaterIntakeManager.swift
//  Keto Macro Tracker
//
//  Manages daily water/hydration tracking
//

import Foundation
import SwiftUI

// MARK: - Water Intake Manager
class WaterIntakeManager: ObservableObject {
    static let shared = WaterIntakeManager()
    
    @Published var todaysWaterIntake: Double = 0.0 // in cups
    
    private let userDefaultsKey = "WaterIntakeData"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Keto recommendation: 0.5-1 oz per pound of body weight
    // Default goal: 8 cups (64 oz) per day, minimum for keto
    var dailyGoal: Double {
        // Could be calculated based on user weight, but defaulting to 8 cups
        return 8.0
    }
    
    var progress: Double {
        guard dailyGoal > 0 else { return 0.0 }
        return min(todaysWaterIntake / dailyGoal, 1.0)
    }
    
    var remaining: Double {
        return max(0, dailyGoal - todaysWaterIntake)
    }
    
    private init() {
        loadTodaysWater()
    }
    
    // MARK: - Public Methods
    
    func addWater(_ amount: Double) {
        todaysWaterIntake += amount
        saveTodaysWater()
        print("💧 Added \(amount) cup\(amount == 1 ? "" : "s") water. Total today: \(String(format: "%.1f", todaysWaterIntake)) cups")
        
        // Update widget
        WidgetDataService.shared.updateWidgetData()
        
        // Check hydration reminder
        NotificationManager.shared.checkHydrationReminder(
            currentWater: todaysWaterIntake,
            waterGoal: dailyGoal
        )
        
        // Sync to Health if enabled (convert cups to fluid ounces for HealthKit)
        if UserDefaults.standard.bool(forKey: "HealthKitAutoSync") {
            let ounces = todaysWaterIntake * 8.0 // 1 cup = 8 fl oz
            HealthKitManager.shared.saveWaterToHealth(amount: ounces)
        }
    }
    
    func removeWater(_ amount: Double) {
        todaysWaterIntake = max(0, todaysWaterIntake - amount)
        saveTodaysWater()
        print("💧 Removed \(amount) cup\(amount == 1 ? "" : "s") water. Total today: \(String(format: "%.1f", todaysWaterIntake)) cups")
        
        // Update widget
        WidgetDataService.shared.updateWidgetData()
    }
    
    func resetDay() {
        todaysWaterIntake = 0.0
        saveTodaysWater()
    }
    
    /// Check for day transition and reload today's water if needed
    /// Call this when app comes to foreground to ensure values reset for new day
    func checkForDayTransition() {
        let todayKey = dateFormatter.string(from: Date())
        let fullKey = "\(userDefaultsKey)_\(todayKey)"
        
        // Check if saved water is from today
        if let savedDateKey = UserDefaults.standard.string(forKey: "\(fullKey)_date"),
           savedDateKey == todayKey {
            // Same day, load the saved value
            if let saved = UserDefaults.standard.object(forKey: fullKey) as? Double {
                todaysWaterIntake = saved
            }
        } else {
            // New day, reset to zero
            print("📅 Day transition detected for water intake, resetting to 0")
            resetDay()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTodaysWater() {
        let todayKey = dateFormatter.string(from: Date())
        let fullKey = "\(userDefaultsKey)_\(todayKey)"
        
        if let saved = UserDefaults.standard.object(forKey: fullKey) as? Double {
            // Check if it's from today
            let savedDateKey = UserDefaults.standard.string(forKey: "\(fullKey)_date")
            if savedDateKey == todayKey {
                todaysWaterIntake = saved
                print("💧 Loaded today's water intake: \(String(format: "%.1f", saved)) cups")
            } else {
                // New day, reset
                resetDay()
            }
        } else {
            todaysWaterIntake = 0.0
        }
    }
    
    private func saveTodaysWater() {
        let todayKey = dateFormatter.string(from: Date())
        let fullKey = "\(userDefaultsKey)_\(todayKey)"
        
        UserDefaults.standard.set(todaysWaterIntake, forKey: fullKey)
        UserDefaults.standard.set(todayKey, forKey: "\(fullKey)_date")
        print("💾 Saved water intake: \(String(format: "%.1f", todaysWaterIntake)) cups")
    }
}

