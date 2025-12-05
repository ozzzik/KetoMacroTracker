//
//  WidgetDataService.swift
//  Keto Macro Tracker
//
//  Service to update widget data in shared UserDefaults
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let appGroupIdentifier = "group.com.whio.KetoMacroTracker"
    
    private init() {}
    
    // MARK: - Update Widget Data
    
    func updateWidgetData() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            // App Group not configured yet - this is OK, widget extension not set up
            // print("⚠️ Could not access App Group UserDefaults - widget extension not configured")
            return
        }
        
        let foodLogManager = FoodLogManager.shared
        let waterManager = WaterIntakeManager.shared
        let fastingManager = FastingManager.shared
        let profileManager = ProfileManager.shared
        
        // Calculate macro goals
        let goals = calculateMacroGoals(profile: profileManager.profile)
        
        // Write current data
        sharedDefaults.set(foodLogManager.totalProtein, forKey: "widget_protein")
        sharedDefaults.set(foodLogManager.netCarbs, forKey: "widget_carbs")
        sharedDefaults.set(foodLogManager.totalFat, forKey: "widget_fat")
        sharedDefaults.set(foodLogManager.totalCalories, forKey: "widget_calories")
        
        sharedDefaults.set(goals.protein, forKey: "widget_proteinGoal")
        sharedDefaults.set(goals.carbs, forKey: "widget_carbsGoal")
        sharedDefaults.set(goals.fat, forKey: "widget_fatGoal")
        sharedDefaults.set(goals.calories, forKey: "widget_caloriesGoal")
        
        sharedDefaults.set(waterManager.todaysWaterIntake, forKey: "widget_waterIntake")
        sharedDefaults.set(waterManager.dailyGoal, forKey: "widget_waterGoal")
        
        // Fasting data
        if fastingManager.currentSession != nil {
            sharedDefaults.set(true, forKey: "widget_isFasting")
            sharedDefaults.set(fastingManager.getFormattedCurrentDuration(), forKey: "widget_fastingDuration")
        } else {
            sharedDefaults.set(false, forKey: "widget_isFasting")
            sharedDefaults.removeObject(forKey: "widget_fastingDuration")
        }
        
        sharedDefaults.synchronize()
        
        // Reload widget timeline (only if WidgetKit is available)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "KetoMacroWidget")
        #endif
        
        print("📱 Widget data updated")
    }
}

