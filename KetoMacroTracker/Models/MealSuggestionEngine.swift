//
//  MealSuggestionEngine.swift
//  Keto Macro Tracker
//
//  Smart meal suggestion engine with personalization
//

import Foundation
import SwiftUI

// MARK: - Meal Suggestion Engine
class MealSuggestionEngine: ObservableObject {
    static let shared = MealSuggestionEngine()
    
    @Published var mealDatabase: [KetoMeal] = []
    @Published var userPreferences: UserPreferences = .default
    @Published var recentMeals: [KetoMeal] = []
    
    private let userDefaultsKey = "UserMealPreferences"
    
    private init() {
        loadMealDatabase()
        loadUserPreferences()
        loadRecentMeals()
    }
    
    // MARK: - Public Methods
    
    /// Get meal suggestions based on remaining macros
    func suggestMeals(
        remainingMacros: MacroTargets,
        category: MealCategory? = nil,
        maxPrepTime: Int? = nil,
        difficulty: DifficultyLevel? = nil,
        macroContext: MacroContext? = nil,
        limit: Int = 10
    ) -> [MealSuggestion] {
        
        let suggestions = mealDatabase.filter { meal in
            guard !remainingMacros.isDepleted else { return false }
            
            let matchesMacroLimits =
                meal.protein <= remainingMacros.flexibleLimit(for: .protein) &&
                meal.netCarbs <= remainingMacros.flexibleLimit(for: .carbs) &&
                meal.fat <= remainingMacros.flexibleLimit(for: .fat)
            
            let matchesCategory = category.map { meal.category == $0 } ?? true
            let matchesPrepTime = maxPrepTime.map { meal.prepTime <= $0 } ?? true
            let matchesDifficulty = difficulty.map { meal.difficulty == $0 } ?? true
            
            return matchesMacroLimits && matchesCategory && matchesPrepTime && matchesDifficulty
        }
        
        // Sort by relevance and return top suggestions
        return suggestions
            .sorted { first, second in
                let firstScore = calculateRelevanceScore(first, remainingMacros, macroContext: macroContext)
                let secondScore = calculateRelevanceScore(second, remainingMacros, macroContext: macroContext)
                return firstScore > secondScore
            }
            .prefix(limit)
            .map { meal in
                let recommendedFocus = macroContext?.primaryContribution(for: meal)
                return MealSuggestion(
                    meal: meal,
                    macroFit: calculateMacroFit(meal, remainingMacros, macroContext: macroContext),
                    estimatedPrepTime: meal.prepTime,
                    difficulty: meal.difficulty,
                    personalizationScore: calculatePersonalizationScore(meal),
                    recommendedFocus: recommendedFocus
                )
            }
    }
    
    /// Get quick meal suggestions for specific categories
    func getQuickMeals(for category: MealCategory, limit: Int = 5) -> [KetoMeal] {
        return mealDatabase
            .filter { $0.category == category && $0.prepTime <= 15 }
            .sorted { $0.prepTime < $1.prepTime }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Add meal to recent meals
    func addToRecentMeals(_ meal: KetoMeal) {
        recentMeals.removeAll { $0.id == meal.id }
        recentMeals.insert(meal, at: 0)
        
        // Keep only last 20 meals
        if recentMeals.count > 20 {
            recentMeals = Array(recentMeals.prefix(20))
        }
        
        saveRecentMeals()
    }
    
    /// Update user preferences
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        saveUserPreferences()
    }
    
    // MARK: - Private Methods
    
    private func calculatePersonalizationScore(_ meal: KetoMeal) -> Double {
        var score = 0.0
        
        // Category preference
        if userPreferences.preferredCategories.contains(meal.category) {
            score += 0.3
        }
        
        // Time-based preferences
        let currentHour = Calendar.current.component(.hour, from: Date())
        if (currentHour < 10 && meal.category == .breakfast) ||
           (currentHour >= 10 && currentHour < 15 && meal.category == .lunch) ||
           (currentHour >= 15 && meal.category == .dinner) {
            score += 0.2
        }
        
        // Recent meal frequency (avoid suggesting same meal too often)
        let recentOccurrences = recentMeals.filter { $0.id == meal.id }.count
        score -= Double(recentOccurrences) * 0.1
        
        // Difficulty preference
        if let preferredDifficulty = userPreferences.preferredDifficulty,
           meal.difficulty == preferredDifficulty {
            score += 0.1
        }
        
        // Prep time preference
        if let maxPrepTime = userPreferences.maxPrepTime,
           meal.prepTime <= maxPrepTime {
            score += 0.1
        }
        
        // Dietary restrictions
        for restriction in userPreferences.dietaryRestrictions {
            if meal.tags.contains(restriction.lowercased()) {
                score += 0.1
            }
        }
        
        // Favorite ingredients
        for ingredient in userPreferences.favoriteIngredients {
            if meal.ingredients.contains(where: { $0.lowercased().contains(ingredient.lowercased()) }) {
                score += 0.05
            }
        }
        
        // Disliked ingredients
        for ingredient in userPreferences.dislikedIngredients {
            if meal.ingredients.contains(where: { $0.lowercased().contains(ingredient.lowercased()) }) {
                score -= 0.2
            }
        }
        
        return min(max(score, 0.0), 1.0)
    }
    
    private func calculateRelevanceScore(_ meal: KetoMeal, _ remaining: MacroTargets, macroContext: MacroContext?) -> Double {
        let macroScore = calculateMacroFit(meal, remaining, macroContext: macroContext).rawValue
        let timeScore = max(0, 1.0 - Double(meal.prepTime) / 60.0) // Prefer faster meals
        let difficultyScore = meal.difficulty == .easy ? 1.0 : meal.difficulty == .medium ? 0.7 : 0.4
        let personalizationScore = calculatePersonalizationScore(meal)
        let focusBoost: Double
        if let context = macroContext,
           let contribution = context.primaryContribution(for: meal),
           contribution == context.focus {
            focusBoost = 0.1
        } else {
            focusBoost = 0
        }
        
        return (macroScore * 0.4 + timeScore * 0.3 + difficultyScore * 0.2 + personalizationScore * 0.1 + focusBoost)
    }
    
    private func calculateMacroFit(_ meal: KetoMeal, _ remaining: MacroTargets, macroContext: MacroContext?) -> MacroFit {
        // Calculate time-based meal expectations
        // The fit should be based on remaining macros AND time of day
        // A meal should be proportional to what's left in the day
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Estimate meals remaining in the day based on time
        // 6am-10am: breakfast time, ~3 meals left
        // 10am-3pm: lunch time, ~2 meals left  
        // 3pm-9pm: dinner time, ~1 meal left
        // 9pm+: late night, ~0.5 meals left
        let mealsRemaining: Double
        switch currentHour {
        case 0..<10: mealsRemaining = 3.0  // Breakfast: 3 meals left
        case 10..<15: mealsRemaining = 2.0  // Lunch: 2 meals left
        case 15..<21: mealsRemaining = 1.0 // Dinner: 1 meal left
        default: mealsRemaining = 0.5       // Late night: 0.5 meals left
        }
        
        // Ideal meal size = remaining macros / meals remaining
        // This ensures meals are proportional to time left in day
        let idealMeal = MacroTargets(
            protein: remaining.protein / max(mealsRemaining, 0.5),
            carbs: remaining.carbs / max(mealsRemaining, 0.5),
            fat: remaining.fat / max(mealsRemaining, 0.5),
            calories: remaining.calories / max(mealsRemaining, 0.5)
        )
        
        // Calculate how well the meal fits the ideal size
        // Ratio of 1.0 = perfect fit (meal uses exactly what's expected)
        let proteinFit = ratio(of: meal.protein, to: idealMeal.protein)
        let carbFit = ratio(of: meal.netCarbs, to: idealMeal.carbs)
        let fatFit = ratio(of: meal.fat, to: idealMeal.fat)
        
        // Carbs are most critical for keto, so weight them more heavily
        var fitValues: [Double] = [
            proteinFit * 0.3,
            carbFit * 0.5,  // Higher weight for carbs (most critical for keto)
            fatFit * 0.2
        ]
        
        // Apply macro focus boost if context is available
        if let context = macroContext {
            switch context.focus {
            case .protein:
                fitValues[0] *= 1.2
            case .fat:
                fitValues[2] *= 1.2
            case .carbs:
                fitValues[1] *= 1.2
            case .balanced:
                break
            }
        }
        
        let weightedFit = fitValues.reduce(0, +)
        
        // Fit thresholds based on how close meal is to ideal size
        // Perfect: within 20% of ideal
        // Good: within 40% of ideal
        // Acceptable: within 60% of ideal
        // Poor: outside acceptable range
        switch weightedFit {
        case 0.8...1.2: return .perfect
        case 0.6...1.4: return .good
        case 0.4...1.6: return .acceptable
        default: return .poor
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMealDatabase() {
        // Load from bundled JSON file or create default meals
        mealDatabase = createDefaultMealDatabase()
    }
    
    private func createDefaultMealDatabase() -> [KetoMeal] {
        return [
            // Breakfast meals
            KetoMeal(
                name: "Keto Pancakes",
                category: .breakfast,
                protein: 15.0,
                carbs: 3.0,
                fat: 25.0,
                calories: 320,
                prepTime: 15,
                difficulty: .easy,
                ingredients: ["Almond flour", "Eggs", "Butter", "Baking powder"],
                instructions: ["Mix dry ingredients", "Add wet ingredients", "Cook on griddle"],
                description: "Fluffy low-carb pancakes perfect for breakfast",
                imageName: nil,
                tags: ["quick", "sweet", "keto-friendly"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Bacon & Eggs",
                category: .breakfast,
                protein: 20.0,
                carbs: 1.0,
                fat: 30.0,
                calories: 350,
                prepTime: 10,
                difficulty: .easy,
                ingredients: ["Bacon", "Eggs", "Butter"],
                instructions: ["Cook bacon", "Fry eggs in bacon fat", "Season to taste"],
                description: "Classic keto breakfast with crispy bacon and fried eggs",
                imageName: nil,
                tags: ["classic", "high-fat", "quick"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            // Lunch meals
            KetoMeal(
                name: "Caesar Salad",
                category: .lunch,
                protein: 18.0,
                carbs: 5.0,
                fat: 22.0,
                calories: 280,
                prepTime: 10,
                difficulty: .easy,
                ingredients: ["Romaine lettuce", "Parmesan cheese", "Caesar dressing", "Croutons (keto)"],
                instructions: ["Wash lettuce", "Add cheese and dressing", "Top with keto croutons"],
                description: "Fresh Caesar salad with keto-friendly croutons",
                imageName: nil,
                tags: ["fresh", "light", "keto-friendly"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            // Dinner meals
            KetoMeal(
                name: "Salmon with Asparagus",
                category: .dinner,
                protein: 35.0,
                carbs: 8.0,
                fat: 20.0,
                calories: 380,
                prepTime: 25,
                difficulty: .medium,
                ingredients: ["Salmon fillet", "Asparagus", "Olive oil", "Lemon", "Herbs"],
                instructions: ["Season salmon", "Roast asparagus", "Cook salmon", "Serve with lemon"],
                description: "Perfectly cooked salmon with roasted asparagus",
                imageName: nil,
                tags: ["healthy", "omega-3", "high-protein"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            // Snack meals
            KetoMeal(
                name: "Avocado & Cheese",
                category: .snack,
                protein: 8.0,
                carbs: 4.0,
                fat: 18.0,
                calories: 200,
                prepTime: 5,
                difficulty: .easy,
                ingredients: ["Avocado", "Cheese", "Salt", "Pepper"],
                instructions: ["Slice avocado", "Add cheese", "Season with salt and pepper"],
                description: "Simple and satisfying keto snack",
                imageName: nil,
                tags: ["quick", "healthy-fats", "simple"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Chicken Zoodle Bowl",
                category: .lunch,
                protein: 28.0,
                carbs: 6.0,
                fat: 18.0,
                calories: 310,
                prepTime: 20,
                difficulty: .medium,
                ingredients: ["Chicken breast", "Zucchini noodles", "Olive oil", "Parmesan", "Garlic"],
                instructions: ["Spiralize zucchini", "Sauté garlic in olive oil", "Cook chicken", "Combine and toss"],
                description: "High-protein bowl with spiralized zucchini noodles",
                imageName: nil,
                tags: ["high-protein", "gluten-free", "meal-prep"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Creamy Avocado Smoothie",
                category: .snack,
                protein: 10.0,
                carbs: 5.0,
                fat: 24.0,
                calories: 280,
                prepTime: 5,
                difficulty: .easy,
                ingredients: ["Avocado", "Unsweetened almond milk", "Spinach", "Collagen powder"],
                instructions: ["Combine all ingredients", "Blend until smooth", "Serve chilled"],
                description: "Rich smoothie perfect for a fat-focused boost",
                imageName: nil,
                tags: ["high-fat", "quick", "dairy-free"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Steak & Broccoli Plate",
                category: .dinner,
                protein: 45.0,
                carbs: 7.0,
                fat: 30.0,
                calories: 520,
                prepTime: 30,
                difficulty: .medium,
                ingredients: ["Ribeye steak", "Broccoli", "Butter", "Garlic", "Sea salt"],
                instructions: ["Season steak", "Pan-sear to preference", "Steam broccoli", "Finish with garlic butter"],
                description: "Protein-forward dinner with rich fats and low carbs",
                imageName: nil,
                tags: ["high-protein", "satisfying", "dinner"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Mediterranean Lettuce Wraps",
                category: .lunch,
                protein: 22.0,
                carbs: 4.0,
                fat: 26.0,
                calories: 360,
                prepTime: 15,
                difficulty: .easy,
                ingredients: ["Ground turkey", "Romaine lettuce", "Feta cheese", "Olives", "Cucumber"],
                instructions: ["Cook turkey with spices", "Chop vegetables", "Assemble wraps"],
                description: "Light, crunchy wraps with balanced macros",
                imageName: nil,
                tags: ["meal-prep", "balanced", "gluten-free"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Cheesy Cauliflower Bake",
                category: .dinner,
                protein: 18.0,
                carbs: 8.0,
                fat: 32.0,
                calories: 350,
                prepTime: 35,
                difficulty: .medium,
                ingredients: ["Cauliflower", "Cheddar cheese", "Heavy cream", "Butter", "Smoked paprika"],
                instructions: ["Steam cauliflower", "Prepare cheese sauce", "Combine and bake until golden"],
                description: "Comforting casserole that delivers serious fat macros",
                imageName: nil,
                tags: ["high-fat", "comfort-food", "vegetarian"],
                servingSize: 1.0,
                servingUnit: "serving"
            ),
            
            KetoMeal(
                name: "Egg & Spinach Muffins",
                category: .breakfast,
                protein: 14.0,
                carbs: 2.0,
                fat: 16.0,
                calories: 210,
                prepTime: 25,
                difficulty: .easy,
                ingredients: ["Eggs", "Spinach", "Cheddar", "Heavy cream"],
                instructions: ["Whisk eggs and cream", "Fold in spinach and cheese", "Bake in muffin tin"],
                description: "Grab-and-go breakfast great for weekly prep",
                imageName: nil,
                tags: ["meal-prep", "breakfast", "high-protein"],
                servingSize: 2.0,
                servingUnit: "muffins"
            ),
            
            KetoMeal(
                name: "Chocolate Chia Pudding",
                category: .dessert,
                protein: 8.0,
                carbs: 7.0,
                fat: 20.0,
                calories: 260,
                prepTime: 10,
                difficulty: .easy,
                ingredients: ["Chia seeds", "Cocoa powder", "Coconut milk", "Vanilla extract"],
                instructions: ["Combine ingredients", "Chill overnight", "Top with nuts"],
                description: "Sweet treat with fiber-rich chia seeds",
                imageName: nil,
                tags: ["sweet", "high-fat", "fiber"],
                servingSize: 1.0,
                servingUnit: "jar"
            )
        ]
    }
    
    // MARK: - Persistence
    
    private func saveUserPreferences() {
        if let encoded = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUserPreferences() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return
        }
        userPreferences = decoded
    }
    
    private func saveRecentMeals() {
        if let encoded = try? JSONEncoder().encode(recentMeals) {
            UserDefaults.standard.set(encoded, forKey: "RecentMeals")
        }
    }
    
    private func loadRecentMeals() {
        guard let data = UserDefaults.standard.data(forKey: "RecentMeals"),
              let decoded = try? JSONDecoder().decode([KetoMeal].self, from: data) else {
            return
        }
        recentMeals = decoded
    }
}

// MARK: - Macro Targets
struct MacroTargets {
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    
    var isDepleted: Bool {
        protein <= 0 && carbs <= 0 && fat <= 0 && calories <= 0
    }
    
    func flexibleLimit(for focus: MacroFocus) -> Double {
        switch focus {
        case .protein:
            return protein > 0 ? protein * 1.2 : 15 // allow modest protein buffer
        case .fat:
            return fat > 0 ? fat * 1.2 : 25
        case .carbs:
            return max(0, carbs)
        case .balanced:
            return calories > 0 ? calories : 0
        }
    }
}

// MARK: - Macro Context
struct MacroContext {
    let goals: MacroTargets
    let remaining: MacroTargets
    
    var focus: MacroFocus {
        let focusScores: [(MacroFocus, Double)] = [
            (.protein, normalizedRemaining(for: .protein)),
            (.fat, normalizedRemaining(for: .fat)),
            (.carbs, normalizedRemaining(for: .carbs))
        ]
        
        guard let top = focusScores.max(by: { $0.1 < $1.1 }), top.1 >= 0.25 else {
            return .balanced
        }
        return top.0
    }
    
    private func normalizedRemaining(for macro: MacroFocus) -> Double {
        let remainingValue: Double
        let goalValue: Double
        
        switch macro {
        case .protein:
            remainingValue = remaining.protein
            goalValue = goals.protein
        case .fat:
            remainingValue = remaining.fat
            goalValue = goals.fat
        case .carbs:
            remainingValue = remaining.carbs
            goalValue = goals.carbs
        case .balanced:
            return 0
        }
        
        guard goalValue > 0 else { return 0 }
        let ratio = remainingValue / goalValue
        return min(max(ratio, 0), 1)
    }
    
    func primaryContribution(for meal: KetoMeal) -> MacroFocus? {
        var contributions: [(MacroFocus, Double)] = []
        
        if remaining.protein > 0 {
            contributions.append((.protein, meal.protein / max(remaining.protein, 1)))
        }
        if remaining.fat > 0 {
            contributions.append((.fat, meal.fat / max(remaining.fat, 1)))
        }
        if remaining.carbs > 0 {
            contributions.append((.carbs, meal.netCarbs / max(remaining.carbs, 1)))
        }
        
        guard let top = contributions.max(by: { $0.1 < $1.1 }), top.1 >= 0.4 else {
            return nil
        }
        
        return top.0
    }
}

// MARK: - Macro Focus
enum MacroFocus: String, Codable, Hashable, CaseIterable {
    case protein
    case fat
    case carbs
    case balanced
    
    var title: String {
        switch self {
        case .protein: return "Protein Boost"
        case .fat: return "Healthy Fats"
        case .carbs: return "Stay Low-Carb"
        case .balanced: return "Balanced Focus"
        }
    }
    
    var detail: String {
        switch self {
        case .protein:
            return "You still have a sizeable protein gap."
        case .fat:
            return "You need more fat to fuel ketosis."
        case .carbs:
            return "Keep carbs minimal to stay in ketosis."
        case .balanced:
            return "Macros are balanced—choose what looks good."
        }
    }
    
    var icon: String {
        switch self {
        case .protein: return "dumbbell"
        case .fat: return "drop.fill"
        case .carbs: return "leaf"
        case .balanced: return "circle.grid.cross"
        }
    }
    
    var color: Color {
        switch self {
        case .protein: return AppColors.protein
        case .fat: return AppColors.fat
        case .carbs: return AppColors.carbs
        case .balanced: return AppColors.primary
        }
    }
}

// MARK: - Helper
private func ratio(of value: Double, to target: Double) -> Double {
    guard target > 0 else {
        return value == 0 ? 1.0 : 2.0
    }
    return value / max(target, 0.1)
}

