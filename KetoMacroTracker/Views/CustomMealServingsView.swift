//
//  CustomMealServingsView.swift
//  Keto Macro Tracker
//
//  View for adjusting individual food serving sizes when adding a custom meal
//

import SwiftUI

struct CustomMealServingsView: View {
    let customMeal: CustomMeal
    let onAdd: (CustomMeal, [CustomMealFood]) -> Void // Pass adjusted foods
    
    @Environment(\.dismiss) var dismiss
    @State private var adjustedFoods: [AdjustedFood]
    
    init(customMeal: CustomMeal, onAdd: @escaping (CustomMeal, [CustomMealFood]) -> Void) {
        self.customMeal = customMeal
        self.onAdd = onAdd
        // Initialize with original servings
        self._adjustedFoods = State(initialValue: customMeal.foods.map { 
            AdjustedFood(id: $0.id, food: $0.food, servings: $0.servings, originalServings: $0.servings)
        })
    }
    
    private var totalNutrition: MacroNutrition {
        let totalProtein = adjustedFoods.reduce(0) { $0 + ($1.food.protein * $1.servings) }
        let totalCarbs = adjustedFoods.reduce(0) { 
            let netCarbs = max(0, $1.food.totalCarbs - $1.food.fiber - $1.food.sugarAlcohols)
            return $0 + (netCarbs * $1.servings)
        }
        let totalFat = adjustedFoods.reduce(0) { $0 + ($1.food.fat * $1.servings) }
        let totalCalories = adjustedFoods.reduce(0) { $0 + ($1.food.calories * $1.servings) }
        
        return MacroNutrition(
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            calories: totalCalories
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Nutrition summary
                    nutritionSection
                    
                    // Foods with adjustable servings
                    foodsSection
                    
                    // Add button
                    addButton
                }
                .padding()
            }
            .navigationTitle("Adjust Servings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(customMeal.name)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
            
            Text(customMeal.description)
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    // MARK: - Nutrition Section
    private var nutritionSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total Nutrition")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 16) {
                    nutritionCard("Protein", value: String(format: "%.1f", totalNutrition.protein), unit: "g", color: AppColors.protein)
                    nutritionCard("Carbs", value: String(format: "%.1f", totalNutrition.carbs), unit: "g", color: AppColors.carbs)
                    nutritionCard("Fat", value: String(format: "%.1f", totalNutrition.fat), unit: "g", color: AppColors.fat)
                    nutritionCard("Cal", value: String(format: "%.0f", totalNutrition.calories), unit: "", color: AppColors.calories)
                }
            }
        }
    }
    
    private func nutritionCard(_ title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(AppTypography.title3)
                    .foregroundColor(color)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppTypography.caption)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Foods Section
    private var foodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adjust Food Servings")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            VStack(spacing: 12) {
                ForEach(adjustedFoods.indices, id: \.self) { index in
                    FoodServingAdjustmentRow(
                        adjustedFood: $adjustedFoods[index],
                        originalServings: adjustedFoods[index].originalServings
                    )
                }
            }
        }
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button(action: {
            // Convert adjusted foods back to CustomMealFood
            let adjustedCustomFoods = adjustedFoods.map { adjustedFood in
                CustomMealFood(
                    id: adjustedFood.id,
                    food: adjustedFood.food,
                    servings: adjustedFood.servings,
                    notes: nil
                )
            }
            
            onAdd(customMeal, adjustedCustomFoods)
            dismiss()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add to Food Log")
            }
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppColors.primary, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
}

// MARK: - Adjusted Food Model
struct AdjustedFood: Identifiable {
    let id: UUID
    let food: USDAFood
    var servings: Double
    let originalServings: Double
}

// MARK: - Food Serving Adjustment Row
struct FoodServingAdjustmentRow: View {
    @Binding var adjustedFood: AdjustedFood
    let originalServings: Double
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                // Food name
                Text(adjustedFood.food.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                    .fontWeight(.semibold)
                
                // Original serving info with unit
                HStack {
                    let servingInfo = adjustedFood.food.formattedServingSize
                    Text("Original: \(String(format: "%.2f", originalServings)) × \(servingInfo)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    if adjustedFood.servings != originalServings {
                        Text("\(adjustedFood.servings > originalServings ? "+" : "")\(String(format: "%.2f", adjustedFood.servings - originalServings))")
                            .font(AppTypography.caption)
                            .foregroundColor(adjustedFood.servings > originalServings ? .green : .orange)
                            .fontWeight(.semibold)
                    }
                }
                
                // Servings stepper
                HStack {
                    Text("Servings:")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if adjustedFood.servings > 0.25 {
                                adjustedFood.servings -= 0.25
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(AppColors.primary)
                                .font(.title3)
                        }
                        
                        Text(String(format: "%.2f", adjustedFood.servings))
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.text)
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            adjustedFood.servings += 0.25
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppColors.primary)
                                .font(.title3)
                        }
                    }
                }
                
                // Nutrition preview for this food
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition: \(String(format: "%.2f", adjustedFood.servings)) × \(adjustedFood.food.formattedServingSize)")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                    
                    HStack(spacing: 12) {
                        let netCarbs = max(0, adjustedFood.food.totalCarbs - adjustedFood.food.fiber - adjustedFood.food.sugarAlcohols)
                        
                        nutritionBadge("P", value: String(format: "%.1f", adjustedFood.food.protein * adjustedFood.servings), color: AppColors.protein)
                        nutritionBadge("C", value: String(format: "%.1f", netCarbs * adjustedFood.servings), color: AppColors.carbs)
                        nutritionBadge("F", value: String(format: "%.1f", adjustedFood.food.fat * adjustedFood.servings), color: AppColors.fat)
                        nutritionBadge("Cal", value: String(format: "%.0f", adjustedFood.food.calories * adjustedFood.servings), color: AppColors.calories)
                    }
                }
            }
        }
    }
    
    private func nutritionBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CustomMealServingsView(
        customMeal: CustomMeal(
            name: "Keto Breakfast",
            category: .breakfast,
            foods: [
                CustomMealFood(food: USDAFood(
                    id: UUID(),
                    fdcId: 1,
                    description: "Eggs",
                    dataType: nil,
                    foodNutrients: [],
                    gtinUpc: nil,
                    publishedDate: nil,
                    brandOwner: nil,
                    brandName: nil,
                    ingredients: nil,
                    servingSize: 100.0,
                    servingSizeUnit: "g",
                    foodCategory: nil
                ), servings: 2.0, notes: nil)
            ],
            totalNutrition: MacroNutrition(protein: 20, carbs: 2, fat: 15, calories: 250),
            prepTime: 5,
            difficulty: .easy,
            description: "Quick keto breakfast",
            dateCreated: Date(),
            lastUsed: nil,
            useCount: 0
        )
    ) { _, _ in }
}

