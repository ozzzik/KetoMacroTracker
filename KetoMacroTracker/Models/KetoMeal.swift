//
//  KetoMeal.swift
//  Keto Macro Tracker
//
//  Data structures for keto meal planning and suggestions
//

import Foundation
import SwiftUI

// MARK: - Keto Meal Data Structure
struct KetoMeal: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: MealCategory
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    let prepTime: Int // minutes
    let difficulty: DifficultyLevel
    let ingredients: [String]
    let instructions: [String]
    let description: String
    let imageName: String?
    let tags: [String]
    let servingSize: Double
    let servingUnit: String
    
    init(
        id: UUID = UUID(),
        name: String,
        category: MealCategory,
        protein: Double,
        carbs: Double,
        fat: Double,
        calories: Double,
        prepTime: Int,
        difficulty: DifficultyLevel,
        ingredients: [String],
        instructions: [String],
        description: String,
        imageName: String?,
        tags: [String],
        servingSize: Double,
        servingUnit: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.calories = calories
        self.prepTime = prepTime
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.instructions = instructions
        self.description = description
        self.imageName = imageName
        self.tags = tags
        self.servingSize = servingSize
        self.servingUnit = servingUnit
    }
    
    // Computed properties
    var netCarbs: Double {
        return carbs // For now, assuming carbs are already net carbs
    }
    
    var isKetoFriendly: Bool {
        return netCarbs <= 10.0 // Consider keto-friendly if under 10g net carbs
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
    
    var nutritionPerServing: MacroNutrition {
        return MacroNutrition(
            protein: protein,
            carbs: carbs,
            fat: fat,
            calories: calories
        )
    }
}

// MARK: - Supporting Types
enum MealCategory: String, CaseIterable, Codable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case dessert = "Dessert"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "apple"
        case .dessert: return "birthday.cake"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .blue
        case .snack: return .green
        case .dessert: return .purple
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Codable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var icon: String {
        switch self {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct MacroNutrition: Codable, Hashable {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    
    var netCarbs: Double {
        return carbs // Assuming carbs are already net carbs
    }
}

// MARK: - Meal Template
struct MealTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let foods: [TemplateFood]
    let totalNutrition: MacroNutrition
    let prepTime: Int
    let difficulty: DifficultyLevel
    let description: String
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        foods: [TemplateFood],
        totalNutrition: MacroNutrition,
        prepTime: Int,
        difficulty: DifficultyLevel,
        description: String,
        dateCreated: Date
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
    }
    
    var totalProtein: Double { totalNutrition.protein }
    var totalCarbs: Double { totalNutrition.carbs }
    var totalFat: Double { totalNutrition.fat }
    var totalCalories: Double { totalNutrition.calories }
}

struct TemplateFood: Identifiable, Codable, Hashable {
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
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: TemplateFood, rhs: TemplateFood) -> Bool {
        return lhs.id == rhs.id
    }
    
    var totalNutrition: MacroNutrition {
        return MacroNutrition(
            protein: food.protein * servings,
            carbs: food.totalCarbs * servings,
            fat: food.fat * servings,
            calories: food.calories * servings
        )
    }
}

// MARK: - Meal Suggestion
struct MealSuggestion: Identifiable, Hashable {
    let id = UUID()
    let meal: KetoMeal
    let macroFit: MacroFit
    let estimatedPrepTime: Int
    let difficulty: DifficultyLevel
    let personalizationScore: Double
    let recommendedFocus: MacroFocus?
    
    var relevanceScore: Double {
        let macroScore = macroFit.rawValue
        let timeScore = max(0, 1.0 - Double(estimatedPrepTime) / 60.0) // Prefer faster meals
        let difficultyScore = difficulty == .easy ? 1.0 : difficulty == .medium ? 0.7 : 0.4
        
        return (macroScore * 0.4 + timeScore * 0.3 + difficultyScore * 0.2 + personalizationScore * 0.1)
    }
}

enum MacroFit: Double, CaseIterable {
    case perfect = 1.0
    case good = 0.8
    case acceptable = 0.6
    case poor = 0.4
    
    var description: String {
        switch self {
        case .perfect: return "Perfect fit"
        case .good: return "Good fit"
        case .acceptable: return "Acceptable"
        case .poor: return "Poor fit"
        }
    }
    
    var color: Color {
        switch self {
        case .perfect: return .green
        case .good: return .green.opacity(0.8)
        case .acceptable: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var preferredCategories: [MealCategory]
    var maxPrepTime: Int?
    var preferredDifficulty: DifficultyLevel?
    var dietaryRestrictions: [String]
    var favoriteIngredients: [String]
    var dislikedIngredients: [String]
    
    static let `default` = UserPreferences(
        preferredCategories: [.breakfast, .lunch, .dinner],
        maxPrepTime: nil,
        preferredDifficulty: nil,
        dietaryRestrictions: [],
        favoriteIngredients: [],
        dislikedIngredients: []
    )
}
