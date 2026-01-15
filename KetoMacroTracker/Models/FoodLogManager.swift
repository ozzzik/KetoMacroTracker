//
//  FoodLogManager.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import Foundation
import SwiftUI

// MARK: - Food Log Errors
enum FoodLogError: LocalizedError {
    case dailyLimitReached(limit: Int, current: Int)
    
    var errorDescription: String? {
        switch self {
        case .dailyLimitReached(let limit, _):
            return "Daily limit reached! You've logged \(limit) foods today. Upgrade to Premium for unlimited logging."
        }
    }
}

// MARK: - Food Log Item
struct LoggedFood: Identifiable, Codable {
    var id = UUID()
    let food: USDAFood
    let servings: Double
    let dateAdded: Date
    
    // Computed properties for total nutrition with safe calculations
    var totalProtein: Double { 
        let result = (food.protein.isFinite ? food.protein : 0.0) * (servings.isFinite ? servings : 0.0)
        return result.isFinite ? result : 0.0
    }
    var totalCarbs: Double { 
        let result = (food.totalCarbs.isFinite ? food.totalCarbs : 0.0) * (servings.isFinite ? servings : 0.0)
        return result.isFinite ? result : 0.0
    }
    var totalFat: Double { 
        let result = (food.fat.isFinite ? food.fat : 0.0) * (servings.isFinite ? servings : 0.0)
        return result.isFinite ? result : 0.0
    }
    var totalCalories: Double { 
        let result = (food.calories.isFinite ? food.calories : 0.0) * (servings.isFinite ? servings : 0.0)
        return result.isFinite ? result : 0.0
    }
    var netCarbs: Double { 
        let carbs = food.totalCarbs.isFinite ? food.totalCarbs : 0.0
        let fiber = food.fiber.isFinite ? food.fiber : 0.0
        let sugarAlcohols = food.sugarAlcohols.isFinite ? food.sugarAlcohols : 0.0
        let serving = servings.isFinite ? servings : 0.0
        let result = max(0, carbs - fiber - sugarAlcohols) * serving
        return result.isFinite ? result : 0.0
    }
}

// MARK: - Food Log Manager
class FoodLogManager: ObservableObject {
    static let shared = FoodLogManager()
    
    @Published var todaysFoods: [LoggedFood] = []
    
    private let historicalDataManager = HistoricalDataManager.shared
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let userDefaultsKey = "FoodLogData"
    
    // Serial queue for food additions to prevent race conditions
    private let additionQueue = DispatchQueue(label: "com.ketomacrotracker.foodaddition", qos: .userInitiated)
    private var isAddingFood = false
    
    private init() {
        loadTodaysFoods()
    }
    
    // Premium limits
    static let freeDailyFoodLimit = 7 // 5-10 range, using 7 as middle
    
    /// Get current daily food count
    var todayFoodCount: Int {
        todaysFoods.filter { 
            Calendar.current.isDate($0.dateAdded, inSameDayAs: Date())
        }.count
    }
    
    /// Check if user can add more foods today (for free users)
    func canAddFoodToday(isPremium: Bool) -> Bool {
        if isPremium {
            return true // Unlimited for premium
        }
        return todayFoodCount < Self.freeDailyFoodLimit
    }
    
    @MainActor
    func addFood(_ food: USDAFood, servings: Double, subscriptionManager: SubscriptionManager? = nil) throws {
        print("🍽️ FoodLogManager.addFood called:")
        print("  - Food: \(food.description)")
        print("  - Servings: \(servings)")
        print("  - Thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Prevent concurrent additions
        guard !isAddingFood else {
            print("⚠️ Food addition already in progress, queuing...")
            // Queue this addition
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                try self.addFood(food, servings: servings, subscriptionManager: subscriptionManager)
            }
            return
        }
        
        isAddingFood = true
        defer { isAddingFood = false }
        
        // Check for day transition first
        historicalDataManager.checkForDayTransition()
        
        // Check premium status and daily limit
        let isPremium = subscriptionManager?.isPremiumActive ?? false
        let todayFoodCount = todaysFoods.filter { 
            Calendar.current.isDate($0.dateAdded, inSameDayAs: Date())
        }.count
        
        // Check if the same food already exists today
        if let existingIndex = todaysFoods.firstIndex(where: { 
            $0.food.description.lowercased() == food.description.lowercased() && 
            Calendar.current.isDate($0.dateAdded, inSameDayAs: Date())
        }) {
            // Combining servings doesn't count as a new entry, so no limit check needed
            let existingFood = todaysFoods[existingIndex]
            let combinedServings = existingFood.servings + servings
            let updatedFood = LoggedFood(
                food: existingFood.food,
                servings: combinedServings,
                dateAdded: existingFood.dateAdded // Keep original date
            )
            todaysFoods[existingIndex] = updatedFood
            
            print("🔄 Combined servings for \(food.description): \(existingFood.servings) + \(servings) = \(combinedServings) servings")
        } else {
            // Check daily limit for free users
            if !isPremium && todayFoodCount >= Self.freeDailyFoodLimit {
                print("⚠️ Daily food limit reached: \(todayFoodCount)/\(Self.freeDailyFoodLimit)")
                throw FoodLogError.dailyLimitReached(limit: Self.freeDailyFoodLimit, current: todayFoodCount)
            }
            
            // Add new food entry
            let loggedFood = LoggedFood(
                food: food,
                servings: servings,
                dateAdded: Date()
            )
            todaysFoods.append(loggedFood)
            
            print("🍽️ Added \(food.description) (\(servings) servings) to food log")
        }
        
        saveTodaysFoods()
        print("🍽️ Total today - Protein: \(totalProtein)g, Carbs: \(totalCarbs)g, Fat: \(totalFat)g")
        print("✅ FoodLogManager.addFood completed successfully")
        
        // Return current count for UI display
        let currentCount = todaysFoods.filter { 
            Calendar.current.isDate($0.dateAdded, inSameDayAs: Date())
        }.count
        print("📊 Today's food count: \(currentCount)\(isPremium ? " (Premium - Unlimited)" : "/\(FoodLogManager.freeDailyFoodLimit)")")
        
        // Check for achievements
        AchievementManager.shared.checkAllAchievements()
        
        // Update widget
        WidgetDataService.shared.updateWidgetData()
        
        // Check notifications
        checkNotifications()
        
        // Sync to Health if enabled
        if UserDefaults.standard.bool(forKey: "HealthKitAutoSync") {
            HealthKitManager.shared.saveNutritionToHealth(
                protein: totalProtein,
                carbs: netCarbs,
                fat: totalFat,
                calories: totalCalories
            )
        }
    }
    
    private func checkNotifications() {
        let notificationManager = NotificationManager.shared
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        
        // Check carb warning
        notificationManager.checkCarbWarning(
            currentCarbs: netCarbs,
            carbGoal: goals.carbs
        )
        
        // Check macro progress
        notificationManager.checkMacroProgress(
            current: totalProtein,
            goal: goals.protein,
            macroType: "Protein"
        )
        notificationManager.checkMacroProgress(
            current: totalFat,
            goal: goals.fat,
            macroType: "Fat"
        )
    }
    
    func removeFood(_ food: LoggedFood) {
        todaysFoods.removeAll { $0.id == food.id }
        saveTodaysFoods()
    }
    
    // MARK: - Computed Properties for Today's Totals
    var totalProtein: Double {
        let result = todaysFoods.reduce(0) { 
            let sum = $0 + $1.totalProtein
            return sum.isFinite ? sum : $0
        }
        return result.isFinite ? result : 0.0
    }
    
    var totalCarbs: Double {
        let result = todaysFoods.reduce(0) { 
            let sum = $0 + $1.totalCarbs
            return sum.isFinite ? sum : $0
        }
        return result.isFinite ? result : 0.0
    }
    
    var totalFat: Double {
        let result = todaysFoods.reduce(0) { 
            let sum = $0 + $1.totalFat
            return sum.isFinite ? sum : $0
        }
        return result.isFinite ? result : 0.0
    }
    
    var totalCalories: Double {
        let result = todaysFoods.reduce(0) { 
            let sum = $0 + $1.totalCalories
            return sum.isFinite ? sum : $0
        }
        return result.isFinite ? result : 0.0
    }
    
    var netCarbs: Double {
        let result = todaysFoods.reduce(0) { 
            let sum = $0 + $1.netCarbs
            return sum.isFinite ? sum : $0
        }
        return result.isFinite ? result : 0.0
    }
    
    // MARK: - Persistence Methods
    func saveTodaysFoods() {
        // Ensure we're on main thread for @Published property access
        let foodsToSave = todaysFoods
        
        // Filter to keep only today's foods
        let today = dateFormatter.string(from: Date())
        let todaysFoodsOnly = foodsToSave.filter { 
            dateFormatter.string(from: $0.dateAdded) == today 
        }
        
        do {
            let encoded = try JSONEncoder().encode(todaysFoodsOnly)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize() // Force immediate write to disk
            print("💾 Saved \(todaysFoodsOnly.count) food items to persistent storage")
            
            // Archive current day's data to historical records
            historicalDataManager.archiveCurrentDay(todaysFoodsOnly)
        } catch {
            print("❌ Failed to save food log data: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            // Don't clear data on save error - keep existing items
        }
    }
    
    func loadTodaysFoods() {
        // Check for day transition first
        historicalDataManager.checkForDayTransition()
        
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("💾 No saved food data found, starting fresh")
            return
        }
        
        do {
            let decodedFoods = try JSONDecoder().decode([LoggedFood].self, from: data)
            
            // Filter to only load today's foods
            let today = dateFormatter.string(from: Date())
            todaysFoods = decodedFoods.filter { 
                dateFormatter.string(from: $0.dateAdded) == today 
            }
            
            print("💾 Loaded \(todaysFoods.count) food items from persistent storage (from \(decodedFoods.count) total)")
        } catch {
            print("❌ Failed to decode food log data: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            print("💾 Starting fresh due to decode error")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            todaysFoods = []
        }
    }
    
    /// Check for day transition and reload today's foods if needed
    /// Call this when app comes to foreground to ensure values reset for new day
    @MainActor
    func checkForDayTransition() {
        // Check for day transition first
        let wasDayTransition = historicalDataManager.checkForDayTransition()
        
        if wasDayTransition {
            print("📅 Day transition detected, reloading today's foods...")
            // Reload today's foods (which will now be empty for the new day)
            loadTodaysFoods()
        } else {
            // Even if no transition, filter out any foods that aren't from today
            // (in case the app was open when day changed)
            let today = dateFormatter.string(from: Date())
            let beforeCount = todaysFoods.count
            todaysFoods = todaysFoods.filter { 
                dateFormatter.string(from: $0.dateAdded) == today 
            }
            if beforeCount != todaysFoods.count {
                print("📅 Filtered out \(beforeCount - todaysFoods.count) food items from previous day")
                saveTodaysFoods()
            }
        }
    }
    
    // MARK: - Data Management
    func clearAllData() {
        todaysFoods.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        historicalDataManager.clearAllHistoricalData()
        print("🗑️ Cleared all food log data")
    }
    
    func clearOldData() {
        // Remove foods older than 7 days from current session
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        todaysFoods = todaysFoods.filter { $0.dateAdded >= sevenDaysAgo }
        saveTodaysFoods()
        
        // Clear old historical data (keeps last 90 days by default)
        historicalDataManager.clearOldData(keepDays: 90)
        print("🗑️ Cleared old food data")
    }
    
    // MARK: - Historical Data Access
    func getHistoricalDataManager() -> HistoricalDataManager {
        return historicalDataManager
    }
}
