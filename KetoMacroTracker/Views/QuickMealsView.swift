//
//  QuickMealsView.swift
//  Keto Macro Tracker
//
//  View for displaying and selecting keto meal suggestions
//

import SwiftUI

struct QuickMealsView: View {
    @StateObject private var suggestionEngine = MealSuggestionEngine.shared
    @StateObject private var customMealManager = CustomMealManager.shared
    @EnvironmentObject var foodLogManager: FoodLogManager
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var mealsTutorialManager = MealsTutorialManager.shared
    
    @State private var selectedCategory: MealCategory? = nil
    @State private var maxPrepTime: Int? = nil
    @State private var difficulty: DifficultyLevel? = nil
    @State private var showingFilters = false
    @State private var showingMealDetail: KetoMeal? = nil
    @State private var showingCreateCustomMeal = false
    @State private var showingCustomMealDetail: CustomMeal? = nil
    @State private var showingMealPrepCalculator = false
    @State private var showingMealTemplates = false
    
    private var macroGoals: MacroTargets {
        calculateMacroGoals(profile: profileManager.profile)
    }
    
    private var remainingMacros: MacroTargets {
        let goals = macroGoals
        let current = (
            protein: foodLogManager.totalProtein,
            carbs: foodLogManager.netCarbs,
            fat: foodLogManager.totalFat,
            calories: foodLogManager.totalCalories
        )
        
        return MacroTargets(
            protein: max(0, goals.protein - current.protein),
            carbs: max(0, goals.carbs - current.carbs),
            fat: max(0, goals.fat - current.fat),
            calories: max(0, goals.calories - current.calories)
        )
    }
    
    private var macroContext: MacroContext {
        MacroContext(goals: macroGoals, remaining: remainingMacros)
    }
    
    private var macroFocus: MacroFocus {
        macroContext.focus
    }
    
    private var hasRemainingMacros: Bool {
        !remainingMacros.isDepleted
    }
    
    private var mealSuggestions: [MealSuggestion] {
        guard hasRemainingMacros else { return [] }
        return suggestionEngine.suggestMeals(
            remainingMacros: remainingMacros,
            category: selectedCategory,
            maxPrepTime: maxPrepTime,
            difficulty: difficulty,
            macroContext: macroContext,
            limit: 12
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with remaining macros
                    remainingMacrosCard
                    
                    if hasRemainingMacros {
                        macroGuidanceCard
                        filterSection
                    } else {
                        goalsCompleteCard
                    }
                    
                    // Meal Templates section
                    if !customMealManager.getTemplates().isEmpty {
                        mealTemplatesSection
                    }
                    
                    // Custom meals section
                    customMealsSection
                    
                    if hasRemainingMacros {
                        // Meal suggestions
                        mealSuggestionsSection
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quick Meals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Create Meal") {
                        showingCreateCustomMeal = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingMealTemplates = true
                        }) {
                            Image(systemName: "doc.text")
                        }
                        
                        Button(action: {
                            showingMealPrepCalculator = true
                        }) {
                            Image(systemName: "calculator")
                        }
                        
                        Button("Filters") {
                            showingFilters = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            MealFiltersView(
                selectedCategory: $selectedCategory,
                maxPrepTime: $maxPrepTime,
                difficulty: $difficulty
            )
        }
        .sheet(item: $showingMealDetail) { meal in
            MealDetailView(meal: meal) { meal in
                addMealToLog(meal)
            }
        }
        .sheet(isPresented: $showingCreateCustomMeal) {
            CreateCustomMealView()
        }
        .sheet(isPresented: $showingMealPrepCalculator) {
            MealPrepCalculatorView()
        }
        .sheet(isPresented: $showingMealTemplates) {
            MealTemplatesView()
        }
        .sheet(item: $showingCustomMealDetail) { customMeal in
            CustomMealDetailView(customMeal: customMeal) { customMeal in
                customMealManager.logCustomMeal(customMeal, to: foodLogManager)
            }
            .environmentObject(foodLogManager)
        }
        .overlay {
            MealsTutorialView(isPresented: $mealsTutorialManager.isShowing)
        }
        .onAppear {
            // Show tutorial on first visit
            if !mealsTutorialManager.hasCompletedTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    mealsTutorialManager.show()
                }
            }
        }
    }
    
    // MARK: - Remaining Macros Card
    private var remainingMacrosCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Remaining Macros")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 20) {
                    macroItem(
                        title: "Protein",
                        value: String(format: "%.1f", remainingMacros.protein),
                        unit: "g",
                        color: AppColors.protein
                    )
                    
                    macroItem(
                        title: "Carbs",
                        value: String(format: "%.1f", remainingMacros.carbs),
                        unit: "g",
                        color: AppColors.carbs
                    )
                    
                    macroItem(
                        title: "Fat",
                        value: String(format: "%.1f", remainingMacros.fat),
                        unit: "g",
                        color: AppColors.fat
                    )
                }
            }
        }
    }
    
    private var macroGuidanceCard: some View {
        AppCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: macroFocus.icon)
                    .font(.title3)
                    .foregroundColor(macroFocus.color)
                    .padding(8)
                    .background(macroFocus.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(macroFocus.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text(macroFocus.detail)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var goalsCompleteCard: some View {
        AppCard {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                    .padding(8)
                    .background(AppColors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Macros on Target")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    Text("You’ve reached today’s macro goals. Log custom meals or make adjustments if you plan to eat more.")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func macroItem(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text(unit)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Filters")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Category filters
                        ForEach(MealCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                    
                                    Text(category.rawValue)
                                        .font(AppTypography.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedCategory == category ? category.color : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(selectedCategory == category ? .white : AppColors.text)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Meal Templates Section
    private var mealTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Meal Templates")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Button(action: {
                    showingMealTemplates = true
                }) {
                    Text("View All")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(customMealManager.getTemplates(limit: 5)) { template in
                        Button(action: {
                            customMealManager.quickAddTemplate(template, servings: 1.0, to: foodLogManager)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: template.category.icon)
                                        .foregroundColor(template.category.color)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(AppColors.primary)
                                        .font(.caption)
                                }
                                
                                Text(template.name)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.text)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    Text("\(String(format: "%.0f", template.netCarbs))g")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.carbs)
                                    
                                    Text("•")
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    Text("\(template.prepTime)m")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                            .padding(12)
                            .frame(width: 140, height: 100)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Meals Section
    private var customMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Custom Meals")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("\(customMealManager.customMeals.count) meals")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if customMealManager.customMeals.isEmpty {
                emptyCustomMealsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(customMealManager.customMeals) { customMeal in
                        CustomMealCard(
                            customMeal: customMeal,
                            onDelete: {
                                customMealManager.deleteCustomMeal(customMeal)
                            }
                        ) {
                            showingCustomMealDetail = customMeal
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                customMealManager.deleteCustomMeal(customMeal)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Custom Meals View
    private var emptyCustomMealsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondaryText)
            
            Text("No custom meals yet")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            Text("Create your first custom meal to save time logging your favorite combinations")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Create Custom Meal") {
                showingCreateCustomMeal = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Meal Suggestions Section
    private var mealSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Suggested Meals")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("\(mealSuggestions.count) meals")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if mealSuggestions.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(mealSuggestions) { suggestion in
                        MealSuggestionCard(suggestion: suggestion) {
                            showingMealDetail = suggestion.meal
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondaryText)
            
            Text("No meals found")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            Text("Try adjusting your filters or check back later")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Helper Functions
    private func addMealToLog(_ meal: KetoMeal) {
        // Convert KetoMeal to USDAFood format for logging
        let usdaFood = convertKetoMealToUSDAFood(meal)
        foodLogManager.addFood(usdaFood, servings: 1.0)
        suggestionEngine.addToRecentMeals(meal)
    }
    
    private func convertKetoMealToUSDAFood(_ meal: KetoMeal) -> USDAFood {
        // Create a basic USDAFood from KetoMeal
        // This is a simplified conversion - in a real app, you'd want more detailed nutrition
        let nutrients: [USDAFoodNutrient] = [
            USDAFoodNutrient(
                nutrientId: 1003, // Protein
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "G",
                value: meal.protein,
                rank: 600,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1005, // Carbs
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                unitName: "G",
                value: meal.carbs,
                rank: 1110,
                indentLevel: 2,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1004, // Fat
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                unitName: "G",
                value: meal.fat,
                rank: 800,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1008, // Calories
                nutrientName: "Energy",
                nutrientNumber: "208",
                unitName: "KCAL",
                value: meal.calories,
                rank: 300,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            )
        ]
        
        return USDAFood(
            id: UUID(),
            fdcId: Int.random(in: 2000000...2999999), // Different range for meal foods
            description: meal.name,
            dataType: "KetoMeal",
            foodNutrients: nutrients,
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: nil,
            ingredients: meal.ingredients.joined(separator: ", "),
            servingSize: nil, // Don't hardcode serving size
            servingSizeUnit: nil,
            foodCategory: meal.category.rawValue
        )
    }
    
    // MARK: - Macro Goals Calculation
    private func calculateMacroGoals(profile: UserProfile) -> MacroTargets {
        // Convert weight from lbs to kg for BMR calculation
        let weightInKg = profile.weight * 0.453592
        
        // Calculate BMR using Mifflin-St Jeor Equation
        let bmr: Double
        if profile.gender == "Male" {
            bmr = (10 * weightInKg) + (6.25 * profile.height) - (5 * Double(profile.age)) + 5
        } else {
            bmr = (10 * weightInKg) + (6.25 * profile.height) - (5 * Double(profile.age)) - 161
        }
        
        // Activity multipliers
        let activityMultiplier: Double
        switch profile.activityLevel {
        case "Sedentary": activityMultiplier = 1.2
        case "Lightly Active": activityMultiplier = 1.375
        case "Moderately Active": activityMultiplier = 1.55
        case "Very Active": activityMultiplier = 1.725
        case "Extremely Active": activityMultiplier = 1.9
        default: activityMultiplier = 1.55
        }
        
        // Goal multipliers
        let goalMultiplier: Double
        switch profile.goal {
        case "Lose Fat": goalMultiplier = 0.80
        case "Maintain Weight": goalMultiplier = 1.0
        case "Gain Weight": goalMultiplier = 1.15
        default: goalMultiplier = 1.0
        }
        
        let tdee = bmr * activityMultiplier
        let calories = tdee * goalMultiplier
        
        // Macro calculations for keto
        let baseProteinPerKg: Double
        switch profile.activityLevel {
        case "Sedentary": baseProteinPerKg = 1.5
        case "Lightly Active": baseProteinPerKg = 1.7
        case "Moderately Active": baseProteinPerKg = 1.9
        case "Very Active": baseProteinPerKg = 2.1
        case "Extremely Active": baseProteinPerKg = 2.3
        default: baseProteinPerKg = 1.9
        }
        
        let proteinPerKg: Double
        switch profile.goal {
        case "Lose Fat": proteinPerKg = baseProteinPerKg + 0.2
        case "Maintain Weight": proteinPerKg = baseProteinPerKg
        case "Gain Weight": proteinPerKg = baseProteinPerKg + 0.1
        default: proteinPerKg = baseProteinPerKg
        }
        
        let protein = weightInKg * proteinPerKg
        let carbs = 20.0 // Standard keto limit
        
        let proteinCalories = protein * 4
        let carbCalories = carbs * 4
        let fatCalories = calories - proteinCalories - carbCalories
        let fat = max(0, fatCalories / 9)
        
        return MacroTargets(
            protein: protein,
            carbs: carbs,
            fat: fat,
            calories: calories
        )
    }
}

// MARK: - Meal Suggestion Card
struct MealSuggestionCard: View {
    let suggestion: MealSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with meal name and category
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.meal.name)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 8) {
                                Image(systemName: suggestion.meal.category.icon)
                                    .font(.caption)
                                    .foregroundColor(suggestion.meal.category.color)
                                
                                Text(suggestion.meal.category.rawValue)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Macro fit indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(suggestion.macroFit.description)
                                .font(AppTypography.caption)
                                .foregroundColor(suggestion.macroFit.color)
                                .fontWeight(.semibold)
                            
                            Circle()
                                .fill(suggestion.macroFit.color)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Nutrition info
                    HStack(spacing: 16) {
                        nutritionItem("P", value: String(format: "%.1f", suggestion.meal.protein), color: AppColors.protein)
                        nutritionItem("C", value: String(format: "%.1f", suggestion.meal.carbs), color: AppColors.carbs)
                        nutritionItem("F", value: String(format: "%.1f", suggestion.meal.fat), color: AppColors.fat)
                        nutritionItem("Cal", value: String(format: "%.0f", suggestion.meal.calories), color: AppColors.calories)
                    }
                    
                    if let focus = suggestion.recommendedFocus {
                        macroFocusBadge(focus)
                    }
                    
                    // Prep time and difficulty
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("\(suggestion.meal.prepTime) min")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: suggestion.meal.difficulty.icon)
                                .font(.caption)
                                .foregroundColor(suggestion.meal.difficulty.color)
                            
                            Text(suggestion.meal.difficulty.rawValue)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func nutritionItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func macroFocusBadge(_ focus: MacroFocus) -> some View {
        HStack(spacing: 6) {
            Image(systemName: focus.icon)
                .font(.caption)
            
            Text(focus.title)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(focus.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(focus.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Custom Meal Card
struct CustomMealCard: View {
    let customMeal: CustomMeal
    var onDelete: (() -> Void)? = nil
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with meal name and category
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customMeal.name)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 8) {
                                Image(systemName: customMeal.category.icon)
                                    .font(.caption)
                                    .foregroundColor(customMeal.category.color)
                                
                                Text(customMeal.category.rawValue)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Delete button and usage stats
                        VStack(alignment: .trailing, spacing: 4) {
                            if let onDelete = onDelete {
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Text("Used \(customMeal.useCount) times")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            if let lastUsed = customMeal.lastUsed {
                                Text("Last: \(formatDate(lastUsed))")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                    
                    // Nutrition info
                    HStack(spacing: 16) {
                        nutritionItem("P", value: String(format: "%.1f", customMeal.totalProtein), color: AppColors.protein)
                        nutritionItem("C", value: String(format: "%.1f", customMeal.totalCarbs), color: AppColors.carbs)
                        nutritionItem("F", value: String(format: "%.1f", customMeal.totalFat), color: AppColors.fat)
                        nutritionItem("Cal", value: String(format: "%.0f", customMeal.totalCalories), color: AppColors.calories)
                    }
                    
                    // Prep time and difficulty
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("\(customMeal.prepTime) min")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: customMeal.difficulty.icon)
                                .font(.caption)
                                .foregroundColor(customMeal.difficulty.color)
                            
                            Text(customMeal.difficulty.rawValue)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func nutritionItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    QuickMealsView()
        .environmentObject(FoodLogManager.shared)
}
