//
//  AchievementManager.swift
//  Keto Macro Tracker
//
//  Manages achievements, badges, and celebrations
//

import Foundation
import SwiftUI

// Import the shared macro calculation function
// (It's in Utils/MacroCalculations.swift and should be accessible)

// MARK: - Achievement Model
enum AchievementType: String, Codable, CaseIterable {
    case firstLog = "first_log"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case perfectDay = "perfect_day"
    case perfectWeek = "perfect_week"
    case ketoMaster = "keto_master"
    case macroMaster = "macro_master"
    case consistency = "consistency"
    case waterGoal = "water_goal"
    case mealPlanner = "meal_planner"
    
    var title: String {
        switch self {
        case .firstLog: return "First Steps"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Month Master"
        case .perfectDay: return "Perfect Day"
        case .perfectWeek: return "Perfect Week"
        case .ketoMaster: return "Keto Master"
        case .macroMaster: return "Macro Master"
        case .consistency: return "Consistency King"
        case .waterGoal: return "Hydration Hero"
        case .mealPlanner: return "Meal Planner"
        }
    }
    
    var description: String {
        switch self {
        case .firstLog: return "Logged your first meal"
        case .weekStreak: return "7 days in a row"
        case .monthStreak: return "30 days in a row"
        case .perfectDay: return "Hit all macro goals in one day"
        case .perfectWeek: return "Perfect macros for 7 days"
        case .ketoMaster: return "Stayed under 20g carbs for 14 days"
        case .macroMaster: return "Hit protein, fat, and carb goals"
        case .consistency: return "80% consistency for 2 weeks"
        case .waterGoal: return "Met water goal 7 days in a row"
        case .mealPlanner: return "Used meal suggestions 10 times"
        }
    }
    
    var icon: String {
        switch self {
        case .firstLog: return "star.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "crown.fill"
        case .perfectDay: return "checkmark.circle.fill"
        case .perfectWeek: return "checkmark.circle.badge.fill"
        case .ketoMaster: return "leaf.fill"
        case .macroMaster: return "target"
        case .consistency: return "chart.line.uptrend.xyaxis"
        case .waterGoal: return "drop.fill"
        case .mealPlanner: return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .firstLog: return .yellow
        case .weekStreak: return .orange
        case .monthStreak: return .purple
        case .perfectDay: return .green
        case .perfectWeek: return .blue
        case .ketoMaster: return .green
        case .macroMaster: return .blue
        case .consistency: return .purple
        case .waterGoal: return .cyan
        case .mealPlanner: return .pink
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let unlockedDate: Date
    let progress: Double // 0.0 to 1.0
    
    init(type: AchievementType, unlockedDate: Date = Date(), progress: Double = 1.0) {
        self.id = UUID()
        self.type = type
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var unlockedAchievements: [Achievement] = []
    @Published var recentUnlocks: [Achievement] = [] // For showing celebrations
    
    private let userDefaultsKey = "Achievements"
    private let foodLogManager = FoodLogManager.shared
    private let historicalDataManager = HistoricalDataManager.shared
    private let waterManager = WaterIntakeManager.shared
    private let trendManager = NetCarbTrendManager.shared
    
    private init() {
        loadAchievements()
        checkAllAchievements()
    }
    
    // MARK: - Public Methods
    
    func checkAllAchievements() {
        checkFirstLog()
        checkStreakAchievements()
        checkPerfectDay()
        checkPerfectWeek()
        checkKetoMaster()
        checkMacroMaster()
        checkConsistency()
        checkWaterGoal()
        checkMealPlanner()
    }
    
    func getAchievementProgress(for type: AchievementType) -> Double {
        if isUnlocked(type) {
            return 1.0
        }
        
        switch type {
        case .firstLog:
            return foodLogManager.todaysFoods.isEmpty ? 0.0 : 1.0
        case .weekStreak:
            let streak = historicalDataManager.getStreakDays()
            return min(Double(streak) / 7.0, 1.0)
        case .monthStreak:
            let streak = historicalDataManager.getStreakDays()
            return min(Double(streak) / 30.0, 1.0)
        case .perfectDay:
            return checkPerfectDayProgress()
        case .perfectWeek:
            return checkPerfectWeekProgress()
        case .ketoMaster:
            return checkKetoMasterProgress()
        case .macroMaster:
            return checkMacroMasterProgress()
        case .consistency:
            return checkConsistencyProgress()
        case .waterGoal:
            return checkWaterGoalProgress()
        case .mealPlanner:
            return 0.0 // Would need to track meal suggestions usage
        }
    }
    
    func isUnlocked(_ type: AchievementType) -> Bool {
        return unlockedAchievements.contains { $0.type == type }
    }
    
    // MARK: - Private Achievement Checks
    
    private func checkFirstLog() {
        if !isUnlocked(.firstLog) && !foodLogManager.todaysFoods.isEmpty {
            unlockAchievement(.firstLog)
        }
    }
    
    private func checkStreakAchievements() {
        let streak = historicalDataManager.getStreakDays()
        
        if streak >= 7 && !isUnlocked(.weekStreak) {
            unlockAchievement(.weekStreak)
        }
        
        if streak >= 30 && !isUnlocked(.monthStreak) {
            unlockAchievement(.monthStreak)
        }
    }
    
    private func checkPerfectDay() {
        if isUnlocked(.perfectDay) { return }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        let protein = foodLogManager.totalProtein
        let carbs = foodLogManager.netCarbs
        let fat = foodLogManager.totalFat
        let calories = foodLogManager.totalCalories
        
        // Within 5% of all goals
        let proteinOK = abs(protein - goals.protein) / goals.protein <= 0.05
        let carbsOK = carbs <= goals.carbs && carbs >= goals.carbs * 0.9
        let fatOK = abs(fat - goals.fat) / goals.fat <= 0.05
        let caloriesOK = abs(calories - goals.calories) / goals.calories <= 0.05
        
        if proteinOK && carbsOK && fatOK && caloriesOK && !foodLogManager.todaysFoods.isEmpty {
            unlockAchievement(.perfectDay)
        }
    }
    
    private func checkPerfectDayProgress() -> Double {
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        let protein = foodLogManager.totalProtein
        let carbs = foodLogManager.netCarbs
        let fat = foodLogManager.totalFat
        let calories = foodLogManager.totalCalories
        
        if foodLogManager.todaysFoods.isEmpty { return 0.0 }
        
        let proteinProgress = min(protein / goals.protein, 1.0)
        let carbsProgress = carbs <= goals.carbs ? min(carbs / goals.carbs, 1.0) : 0.0
        let fatProgress = min(fat / goals.fat, 1.0)
        let caloriesProgress = min(calories / goals.calories, 1.0)
        
        return (proteinProgress + carbsProgress + fatProgress + caloriesProgress) / 4.0
    }
    
    private func checkPerfectWeek() {
        if isUnlocked(.perfectWeek) { return }
        
        let recentSummaries = historicalDataManager.dailySummaries.prefix(7)
        guard recentSummaries.count == 7 else { return }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        var perfectDays = 0
        
        for summary in recentSummaries {
            let proteinOK = abs(summary.totalProtein - goals.protein) / goals.protein <= 0.1
            let carbsOK = summary.netCarbs <= goals.carbs
            let fatOK = abs(summary.totalFat - goals.fat) / goals.fat <= 0.1
            let caloriesOK = abs(summary.totalCalories - goals.calories) / goals.calories <= 0.1
            
            if proteinOK && carbsOK && fatOK && caloriesOK {
                perfectDays += 1
            }
        }
        
        if perfectDays == 7 {
            unlockAchievement(.perfectWeek)
        }
    }
    
    private func checkPerfectWeekProgress() -> Double {
        let recentSummaries = historicalDataManager.dailySummaries.prefix(7)
        guard !recentSummaries.isEmpty else { return 0.0 }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        var perfectDays = 0
        
        for summary in recentSummaries {
            let proteinOK = abs(summary.totalProtein - goals.protein) / goals.protein <= 0.1
            let carbsOK = summary.netCarbs <= goals.carbs
            let fatOK = abs(summary.totalFat - goals.fat) / goals.fat <= 0.1
            let caloriesOK = abs(summary.totalCalories - goals.calories) / goals.calories <= 0.1
            
            if proteinOK && carbsOK && fatOK && caloriesOK {
                perfectDays += 1
            }
        }
        
        return Double(perfectDays) / 7.0
    }
    
    private func checkKetoMaster() {
        if isUnlocked(.ketoMaster) { return }
        
        let recentSummaries = historicalDataManager.dailySummaries.prefix(14)
        guard recentSummaries.count == 14 else { return }
        
        let ketoDays = recentSummaries.filter { $0.netCarbs <= 20.0 }.count
        if ketoDays == 14 {
            unlockAchievement(.ketoMaster)
        }
    }
    
    private func checkKetoMasterProgress() -> Double {
        let recentSummaries = historicalDataManager.dailySummaries.prefix(14)
        guard !recentSummaries.isEmpty else { return 0.0 }
        
        let ketoDays = recentSummaries.filter { $0.netCarbs <= 20.0 }.count
        return min(Double(ketoDays) / 14.0, 1.0)
    }
    
    private func checkMacroMaster() {
        if isUnlocked(.macroMaster) { return }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        let protein = foodLogManager.totalProtein
        let carbs = foodLogManager.netCarbs
        let fat = foodLogManager.totalFat
        
        let proteinOK = abs(protein - goals.protein) / goals.protein <= 0.1
        let carbsOK = carbs <= goals.carbs && carbs >= goals.carbs * 0.8
        let fatOK = abs(fat - goals.fat) / goals.fat <= 0.1
        
        if proteinOK && carbsOK && fatOK && !foodLogManager.todaysFoods.isEmpty {
            unlockAchievement(.macroMaster)
        }
    }
    
    private func checkMacroMasterProgress() -> Double {
        if foodLogManager.todaysFoods.isEmpty { return 0.0 }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        let protein = foodLogManager.totalProtein
        let carbs = foodLogManager.netCarbs
        let fat = foodLogManager.totalFat
        
        let proteinProgress = min(protein / goals.protein, 1.0)
        let carbsProgress = carbs <= goals.carbs ? min(carbs / goals.carbs, 1.0) : 0.0
        let fatProgress = min(fat / goals.fat, 1.0)
        
        return (proteinProgress + carbsProgress + fatProgress) / 3.0
    }
    
    private func checkConsistency() {
        if isUnlocked(.consistency) { return }
        
        let recentSummaries = historicalDataManager.dailySummaries.prefix(14)
        guard recentSummaries.count == 14 else { return }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        var consistentDays = 0
        
        for summary in recentSummaries {
            let carbsOK = summary.netCarbs <= goals.carbs
            if carbsOK {
                consistentDays += 1
            }
        }
        
        let consistency = Double(consistentDays) / 14.0
        if consistency >= 0.8 {
            unlockAchievement(.consistency)
        }
    }
    
    private func checkConsistencyProgress() -> Double {
        let recentSummaries = historicalDataManager.dailySummaries.prefix(14)
        guard !recentSummaries.isEmpty else { return 0.0 }
        
        let goals = calculateMacroGoals(profile: ProfileManager.shared.profile)
        var consistentDays = 0
        
        for summary in recentSummaries {
            let carbsOK = summary.netCarbs <= goals.carbs
            if carbsOK {
                consistentDays += 1
            }
        }
        
        let consistency = Double(consistentDays) / 14.0
        return min(consistency / 0.8, 1.0) // Normalize to 0.8 threshold
    }
    
    private func checkWaterGoal() {
        if isUnlocked(.waterGoal) { return }
        // This would need to track water goal completion over 7 days
        // For now, just check if today's goal is met
        if waterManager.todaysWaterIntake >= waterManager.dailyGoal {
            // Would need to track this over 7 days
        }
    }
    
    private func checkWaterGoalProgress() -> Double {
        return min(waterManager.todaysWaterIntake / waterManager.dailyGoal, 1.0)
    }
    
    private func checkMealPlanner() {
        // Would need to track meal suggestion usage
        // For now, placeholder
    }
    
    // MARK: - Achievement Unlocking
    
    private func unlockAchievement(_ type: AchievementType) {
        guard !isUnlocked(type) else { return }
        
        let achievement = Achievement(type: type)
        unlockedAchievements.append(achievement)
        recentUnlocks.append(achievement)
        
        // Keep only last 5 recent unlocks
        if recentUnlocks.count > 5 {
            recentUnlocks.removeFirst()
        }
        
        saveAchievements()
        print("🏆 Achievement unlocked: \(type.title)")
    }
    
    // MARK: - Persistence
    
    private func loadAchievements() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data) else {
            print("🏆 No achievements found, starting fresh")
            return
        }
        
        unlockedAchievements = decoded
        print("🏆 Loaded \(unlockedAchievements.count) achievements")
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved \(unlockedAchievements.count) achievements")
        }
    }
}

