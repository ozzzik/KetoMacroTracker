//
//  CustomMealManager.swift
//  Keto Macro Tracker
//
//  Manager for user-created custom meals and templates
//

import Foundation
import SwiftUI

// MARK: - Custom Meal Data Structure
struct CustomMeal: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: MealCategory
    let foods: [CustomMealFood]
    let totalNutrition: MacroNutrition
    let prepTime: Int
    let difficulty: DifficultyLevel
    let description: String
    let dateCreated: Date
    let lastUsed: Date?
    let useCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        category: MealCategory,
        foods: [CustomMealFood],
        totalNutrition: MacroNutrition,
        prepTime: Int,
        difficulty: DifficultyLevel,
        description: String,
        dateCreated: Date,
        lastUsed: Date?,
        useCount: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.foods = foods
        self.totalNutrition = totalNutrition
        self.prepTime = prepTime
        self.difficulty = difficulty
        self.description = description
        self.dateCreated = dateCreated
        self.lastUsed = lastUsed
        self.useCount = useCount
    }
    
    var totalProtein: Double { totalNutrition.protein }
    var totalCarbs: Double { totalNutrition.carbs }
    var totalFat: Double { totalNutrition.fat }
    var totalCalories: Double { totalNutrition.calories }
    
    var netCarbs: Double { totalNutrition.carbs }
    
    var isKetoFriendly: Bool {
        return netCarbs <= 10.0
    }
    
    var ketoScore: Int {
        switch netCarbs {
        case 0..<5: return 100
        case 5..<10: return 90
        case 10..<15: return 70
        case 15..<20: return 50
        default: return 30
        }
    }
}

struct CustomMealFood: Identifiable, Codable, Hashable {
    let id: UUID
    let food: USDAFood
    let servings: Double
    let notes: String?
    
    init(id: UUID = UUID(), food: USDAFood, servings: Double, notes: String?) {
        self.id = id
        self.food = food
        self.servings = servings
        self.notes = notes
    }
    
    var totalNutrition: MacroNutrition {
        // Calculate net carbs (total carbs - fiber - sugar alcohols)
        let netCarbs = max(0, food.totalCarbs - food.fiber - food.sugarAlcohols)
        
        return MacroNutrition(
            protein: food.protein * servings,
            carbs: netCarbs * servings, // Use net carbs, not total carbs
            fat: food.fat * servings,
            calories: food.calories * servings
        )
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: CustomMealFood, rhs: CustomMealFood) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Custom Meal Manager
class CustomMealManager: ObservableObject {
    static let shared = CustomMealManager()
    
    @Published var customMeals: [CustomMeal] = []
    @Published var recentMeals: [CustomMeal] = []
    @Published var mealTemplates: [CustomMeal] = [] // Templates are marked custom meals
    
    private let userDefaultsKey = "CustomMeals"
    private let recentMealsKey = "RecentCustomMeals"
    private let templatesKey = "MealTemplates"
    
    private init() {
        loadCustomMeals()
        loadRecentMeals()
        loadTemplates()
    }
    
    // MARK: - Public Methods
    
    /// Create a new custom meal
    func createCustomMeal(
        name: String,
        category: MealCategory,
        foods: [CustomMealFood],
        prepTime: Int,
        difficulty: DifficultyLevel,
        description: String
    ) -> CustomMeal {
        
        let totalNutrition = calculateTotalNutrition(from: foods)
        
        let customMeal = CustomMeal(
            name: name,
            category: category,
            foods: foods,
            totalNutrition: totalNutrition,
            prepTime: prepTime,
            difficulty: difficulty,
            description: description,
            dateCreated: Date(),
            lastUsed: nil,
            useCount: 0
        )
        
        customMeals.append(customMeal)
        saveCustomMeals()
        
        return customMeal
    }
    
    /// Update an existing custom meal
    func updateCustomMeal(_ meal: CustomMeal, with newData: CustomMeal) {
        if let index = customMeals.firstIndex(where: { $0.id == meal.id }) {
            customMeals[index] = newData
            saveCustomMeals()
        }
    }
    
    /// Delete a custom meal
    func deleteCustomMeal(_ meal: CustomMeal) {
        customMeals.removeAll { $0.id == meal.id }
        recentMeals.removeAll { $0.id == meal.id }
        saveCustomMeals()
        saveRecentMeals()
    }
    
    /// Log a custom meal to food diary
    func logCustomMeal(_ meal: CustomMeal, to foodLogManager: FoodLogManager) {
        // Add each food in the custom meal to the food log
        for customFood in meal.foods {
            foodLogManager.addFood(customFood.food, servings: customFood.servings)
        }
        
        // Update meal usage statistics
        updateMealUsage(meal)
        
        // Add to recent meals
        addToRecentMeals(meal)
    }
    
    func addFoodToLog(_ food: USDAFood, servings: Double, to foodLogManager: FoodLogManager) {
        foodLogManager.addFood(food, servings: servings)
    }
    
    func updateMealUsageStats(_ meal: CustomMeal) {
        updateMealUsage(meal)
        addToRecentMeals(meal)
    }
    
    /// Get custom meals for a specific category
    func getCustomMeals(for category: MealCategory? = nil) -> [CustomMeal] {
        if let category = category {
            return customMeals.filter { $0.category == category }
        }
        return customMeals
    }
    
    /// Get most frequently used custom meals
    func getFrequentMeals(limit: Int = 5) -> [CustomMeal] {
        return customMeals
            .sorted { $0.useCount > $1.useCount }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get recently used custom meals
    func getRecentMeals(limit: Int = 5) -> [CustomMeal] {
        return recentMeals.prefix(limit).map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func calculateTotalNutrition(from foods: [CustomMealFood]) -> MacroNutrition {
        let totalProtein = foods.reduce(0) { $0 + $1.totalNutrition.protein }
        let totalCarbs = foods.reduce(0) { $0 + $1.totalNutrition.carbs }
        let totalFat = foods.reduce(0) { $0 + $1.totalNutrition.fat }
        let totalCalories = foods.reduce(0) { $0 + $1.totalNutrition.calories }
        
        return MacroNutrition(
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            calories: totalCalories
        )
    }
    
    private func updateMealUsage(_ meal: CustomMeal) {
        if let index = customMeals.firstIndex(where: { $0.id == meal.id }) {
            var updatedMeal = customMeals[index]
            updatedMeal = CustomMeal(
                id: updatedMeal.id,
                name: updatedMeal.name,
                category: updatedMeal.category,
                foods: updatedMeal.foods,
                totalNutrition: updatedMeal.totalNutrition,
                prepTime: updatedMeal.prepTime,
                difficulty: updatedMeal.difficulty,
                description: updatedMeal.description,
                dateCreated: updatedMeal.dateCreated,
                lastUsed: Date(),
                useCount: updatedMeal.useCount + 1
            )
            customMeals[index] = updatedMeal
            saveCustomMeals()
        }
    }
    
    private func addToRecentMeals(_ meal: CustomMeal) {
        recentMeals.removeAll { $0.id == meal.id }
        recentMeals.insert(meal, at: 0)
        
        // Keep only last 20 meals
        if recentMeals.count > 20 {
            recentMeals = Array(recentMeals.prefix(20))
        }
        
        saveRecentMeals()
    }
    
    // MARK: - Persistence
    
    private func saveCustomMeals() {
        if let encoded = try? JSONEncoder().encode(customMeals) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadCustomMeals() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([CustomMeal].self, from: data) else {
            return
        }
        customMeals = decoded
    }
    
    private func saveRecentMeals() {
        if let encoded = try? JSONEncoder().encode(recentMeals) {
            UserDefaults.standard.set(encoded, forKey: recentMealsKey)
        }
    }
    
    private func loadRecentMeals() {
        guard let data = UserDefaults.standard.data(forKey: recentMealsKey),
              let decoded = try? JSONDecoder().decode([CustomMeal].self, from: data) else {
            return
        }
        recentMeals = decoded
    }
    
    // MARK: - Template Methods
    
    func saveAsTemplate(_ meal: CustomMeal) {
        // Remove if already exists
        mealTemplates.removeAll { $0.id == meal.id }
        
        // Add to templates
        mealTemplates.insert(meal, at: 0)
        
        // Keep only last 20 templates
        if mealTemplates.count > 20 {
            mealTemplates = Array(mealTemplates.prefix(20))
        }
        
        saveTemplates()
        print("📋 Saved as template: \(meal.name)")
    }
    
    func removeTemplate(_ meal: CustomMeal) {
        mealTemplates.removeAll { $0.id == meal.id }
        saveTemplates()
    }
    
    func isTemplate(_ meal: CustomMeal) -> Bool {
        return mealTemplates.contains { $0.id == meal.id }
    }
    
    func getTemplates(limit: Int = 10) -> [CustomMeal] {
        return Array(mealTemplates.prefix(limit))
    }
    
    func quickAddTemplate(_ template: CustomMeal, servings: Double = 1.0, to foodLogManager: FoodLogManager) {
        // Add each food from template to food log
        for customFood in template.foods {
            let adjustedServings = customFood.servings * servings
            foodLogManager.addFood(customFood.food, servings: adjustedServings)
        }
        
        // Update template usage
        if let index = mealTemplates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated = CustomMeal(
                id: updated.id,
                name: updated.name,
                category: updated.category,
                foods: updated.foods,
                totalNutrition: updated.totalNutrition,
                prepTime: updated.prepTime,
                difficulty: updated.difficulty,
                description: updated.description,
                dateCreated: updated.dateCreated,
                lastUsed: Date(),
                useCount: updated.useCount + 1
            )
            mealTemplates[index] = updated
            saveTemplates()
        }
        
        print("✅ Quick added template: \(template.name)")
    }
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(mealTemplates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
    
    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: templatesKey),
              let decoded = try? JSONDecoder().decode([CustomMeal].self, from: data) else {
            return
        }
        mealTemplates = decoded
        print("📋 Loaded \(mealTemplates.count) meal templates")
    }
}

// MARK: - Custom Meal Creation Helper
struct CustomMealBuilder {
    var name: String = ""
    var category: MealCategory = .breakfast
    var foods: [CustomMealFood] = []
    var prepTime: Int = 5
    var difficulty: DifficultyLevel = .easy
    var description: String = ""
    
    var totalNutrition: MacroNutrition {
        let totalProtein = foods.reduce(0) { $0 + $1.totalNutrition.protein }
        let totalCarbs = foods.reduce(0) { $0 + $1.totalNutrition.carbs }
        let totalFat = foods.reduce(0) { $0 + $1.totalNutrition.fat }
        let totalCalories = foods.reduce(0) { $0 + $1.totalNutrition.calories }
        
        return MacroNutrition(
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            calories: totalCalories
        )
    }
    
    var isValid: Bool {
        return !name.isEmpty && !foods.isEmpty
    }
}

