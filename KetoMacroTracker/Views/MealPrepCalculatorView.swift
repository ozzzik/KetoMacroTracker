//
//  MealPrepCalculatorView.swift
//  Keto Macro Tracker
//
//  Calculator for scaling meals to meal prep portions
//

import SwiftUI

struct MealPrepCalculatorView: View {
    @StateObject private var suggestionEngine = MealSuggestionEngine.shared
    @StateObject private var customMealManager = CustomMealManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMealType: MealType = .ketoMeal
    @State private var selectedKetoMeal: KetoMeal? = nil
    @State private var selectedCustomMeal: CustomMeal? = nil
    @State private var numberOfServings: Double = 4.0
    @State private var showingMealPicker = false
    
    enum MealType {
        case ketoMeal
        case customMeal
    }
    
    var scaledNutrition: MacroNutrition? {
        let baseNutrition: MacroNutrition
        let baseServings: Double
        
        if let ketoMeal = selectedKetoMeal {
            baseNutrition = MacroNutrition(
                protein: ketoMeal.protein,
                carbs: ketoMeal.carbs,
                fat: ketoMeal.fat,
                calories: ketoMeal.calories
            )
            baseServings = ketoMeal.servingSize
        } else if let customMeal = selectedCustomMeal {
            baseNutrition = customMeal.totalNutrition
            baseServings = 1.0 // Custom meals are typically 1 serving
        } else {
            return nil
        }
        
        let scaleFactor = numberOfServings / baseServings
        
        return MacroNutrition(
            protein: baseNutrition.protein * scaleFactor,
            carbs: baseNutrition.carbs * scaleFactor,
            fat: baseNutrition.fat * scaleFactor,
            calories: baseNutrition.calories * scaleFactor
        )
    }
    
    var hasSelectedMeal: Bool {
        selectedKetoMeal != nil || selectedCustomMeal != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Meal Selection
                    mealSelectionSection
                    
                    if hasSelectedMeal {
                        // Servings Input
                        servingsSection
                        
                        // Scaled Nutrition
                        scaledNutritionSection
                        
                        // Scaled Ingredients (if custom meal)
                        if selectedCustomMeal != nil {
                            scaledIngredientsSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    } else {
                        // Empty State
                        emptyStateSection
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .background(AppColors.background)
            .navigationTitle("Meal Prep Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMealPicker) {
                MealPickerView(
                    mealType: selectedMealType,
                    onSelectKetoMeal: { meal in
                        selectedKetoMeal = meal
                        selectedCustomMeal = nil
                    },
                    onSelectCustomMeal: { meal in
                        selectedCustomMeal = meal
                        selectedKetoMeal = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Meal Selection Section
    private var mealSelectionSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Meal")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                // Meal Type Picker
                Picker("Meal Type", selection: $selectedMealType) {
                    Text("Keto Meals").tag(MealType.ketoMeal)
                    Text("Custom Meals").tag(MealType.customMeal)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedMealType) {
                    // Reset selection when switching types
                    selectedKetoMeal = nil
                    selectedCustomMeal = nil
                }
                
                // Selected Meal Display
                if let ketoMeal = selectedKetoMeal {
                    Button(action: {
                        showingMealPicker = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ketoMeal.name)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                                
                                Text("\(String(format: "%.1f", ketoMeal.servingSize)) \(ketoMeal.servingUnit) • \(ketoMeal.prepTime) min")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(8)
                    }
                } else if let customMeal = selectedCustomMeal {
                    Button(action: {
                        showingMealPicker = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(customMeal.name)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                                
                                Text("\(customMeal.prepTime) min • \(customMeal.difficulty.rawValue)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        showingMealPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text("Choose a meal to scale")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                            Spacer()
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Servings Section
    private var servingsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Number of Servings")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack {
                    Button(action: {
                        if numberOfServings > 1 {
                            numberOfServings -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(numberOfServings > 1 ? AppColors.primary : .gray)
                    }
                    .disabled(numberOfServings <= 1)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(String(format: "%.0f", numberOfServings))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        
                        Text("servings")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        numberOfServings += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                // Slider
                Slider(value: $numberOfServings, in: 1...20, step: 1)
                    .accentColor(AppColors.primary)
                
                // Quick buttons
                HStack(spacing: 12) {
                    ForEach([2.0, 4.0, 6.0, 8.0], id: \.self) { servings in
                        Button(action: {
                            numberOfServings = servings
                        }) {
                            Text("\(String(format: "%.0f", servings))")
                                .font(AppTypography.caption)
                                .foregroundColor(numberOfServings == servings ? .white : AppColors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    numberOfServings == servings ?
                                    AppColors.primary :
                                    AppColors.secondaryBackground
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Scaled Nutrition Section
    private var scaledNutritionSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Total Nutrition")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if let nutrition = scaledNutrition {
                    VStack(spacing: 12) {
                        nutritionRow(
                            title: "Protein",
                            value: "\(String(format: "%.1f", nutrition.protein))g",
                            color: AppColors.protein
                        )
                        
                        nutritionRow(
                            title: "Net Carbs",
                            value: "\(String(format: "%.1f", nutrition.carbs))g",
                            color: AppColors.carbs
                        )
                        
                        nutritionRow(
                            title: "Fat",
                            value: "\(String(format: "%.1f", nutrition.fat))g",
                            color: AppColors.fat
                        )
                        
                        nutritionRow(
                            title: "Calories",
                            value: "\(String(format: "%.0f", nutrition.calories))",
                            color: AppColors.calories
                        )
                    }
                    
                    Divider()
                    
                    // Per serving breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Per Serving")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        HStack {
                            Text("Protein: \(String(format: "%.1f", nutrition.protein / numberOfServings))g")
                            Spacer()
                            Text("Carbs: \(String(format: "%.1f", nutrition.carbs / numberOfServings))g")
                            Spacer()
                            Text("Fat: \(String(format: "%.1f", nutrition.fat / numberOfServings))g")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Scaled Ingredients Section
    private var scaledIngredientsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Scaled Ingredients")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if let customMeal = selectedCustomMeal {
                    ForEach(customMeal.foods, id: \.id) { food in
                        HStack {
                            Text(food.food.description)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.2f", food.servings * numberOfServings)) servings")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Add scaled meal to log (for one serving)
                if let ketoMeal = selectedKetoMeal {
                    // Would need to convert KetoMeal to USDAFood or create a food entry
                    // For now, just show a message
                    print("Would add \(ketoMeal.name) to log")
                } else if selectedCustomMeal != nil {
                    // Add custom meal foods to log
                    print("Would add custom meal to log")
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add 1 Serving to Today's Log")
                        .font(AppTypography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        AppCard {
            VStack(spacing: 16) {
                Image(systemName: "calculator")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.secondaryText)
                
                Text("Select a Meal")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text("Choose a meal from your keto meals or custom meals to calculate scaled nutrition for meal prep")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - Helper Views
    private func nutritionRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Meal Picker View
struct MealPickerView: View {
    let mealType: MealPrepCalculatorView.MealType
    let onSelectKetoMeal: (KetoMeal) -> Void
    let onSelectCustomMeal: (CustomMeal) -> Void
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var suggestionEngine = MealSuggestionEngine.shared
    @StateObject private var customMealManager = CustomMealManager.shared
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                switch mealType {
                case .ketoMeal:
                    ForEach(filteredKetoMeals, id: \.id) { meal in
                        Button(action: {
                            onSelectKetoMeal(meal)
                            dismiss()
                        }) {
                            MealRow(meal: meal)
                        }
                    }
                case .customMeal:
                    ForEach(filteredCustomMeals, id: \.id) { meal in
                        Button(action: {
                            onSelectCustomMeal(meal)
                            dismiss()
                        }) {
                            CustomMealRow(meal: meal)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Meal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var filteredKetoMeals: [KetoMeal] {
        let meals = suggestionEngine.mealDatabase
        if searchText.isEmpty {
            return meals
        }
        return meals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredCustomMeals: [CustomMeal] {
        let meals = customMealManager.customMeals
        if searchText.isEmpty {
            return meals
        }
        return meals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Meal Row Views
struct MealRow: View {
    let meal: KetoMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.name)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack {
                Text("\(String(format: "%.1f", meal.protein))g P")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.protein)
                
                Text("\(String(format: "%.1f", meal.carbs))g C")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.carbs)
                
                Text("\(String(format: "%.1f", meal.fat))g F")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.fat)
                
                Spacer()
                
                Text("\(meal.prepTime) min")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CustomMealRow: View {
    let meal: CustomMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.name)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack {
                Text("\(String(format: "%.1f", meal.totalProtein))g P")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.protein)
                
                Text("\(String(format: "%.1f", meal.totalCarbs))g C")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.carbs)
                
                Text("\(String(format: "%.1f", meal.totalFat))g F")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.fat)
                
                Spacer()
                
                Text("\(meal.prepTime) min")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MealPrepCalculatorView()
}

