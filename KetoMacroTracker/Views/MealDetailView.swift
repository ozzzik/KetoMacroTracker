//
//  MealDetailView.swift
//  Keto Macro Tracker
//
//  Detailed view for individual keto meals
//

import SwiftUI

struct MealDetailView: View {
    let meal: KetoMeal
    let onAddToLog: (KetoMeal) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingAddConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Nutrition info
                    nutritionSection
                    
                    // Ingredients
                    ingredientsSection
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add to Log") {
                        showingAddConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert("Add to Food Log", isPresented: $showingAddConfirmation) {
            Button("Add") {
                onAddToLog(meal)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add \(meal.name) to your food log?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.category.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(meal.category.color)
                        .fontWeight(.semibold)
                    
                    Text(meal.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(meal.prepTime) min")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                        .fontWeight(.bold)
                    
                    Text("Prep Time")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            // Keto score and difficulty
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("Keto Score: \(meal.ketoScore)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.text)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: meal.difficulty.icon)
                        .foregroundColor(meal.difficulty.color)
                        .font(.caption)
                    
                    Text(meal.difficulty.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.text)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Nutrition Section
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition (per serving)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack(spacing: 20) {
                nutritionCard("Protein", value: String(format: "%.1f", meal.protein), unit: "g", color: AppColors.protein)
                nutritionCard("Carbs", value: String(format: "%.1f", meal.carbs), unit: "g", color: AppColors.carbs)
                nutritionCard("Fat", value: String(format: "%.1f", meal.fat), unit: "g", color: AppColors.fat)
                nutritionCard("Calories", value: String(format: "%.0f", meal.calories), unit: "kcal", color: AppColors.calories)
            }
        }
    }
    
    private func nutritionCard(_ title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text(unit)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(meal.ingredients, id: \.self) { ingredient in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.accent)
                        
                        Text(ingredient)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(meal.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(AppTypography.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(width: 20, height: 20)
                            .background(AppColors.accent)
                            .clipShape(Circle())
                        
                        Text(instruction)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    MealDetailView(
        meal: KetoMeal(
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
        )
    ) { _ in }
}
