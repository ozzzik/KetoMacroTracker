//
//  CustomMealDetailView.swift
//  Keto Macro Tracker
//
//  Detailed view for custom meals
//

import SwiftUI

struct CustomMealDetailView: View {
    let customMeal: CustomMeal
    let onAddToLog: (CustomMeal) -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var foodLogManager: FoodLogManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var customMealManager = CustomMealManager.shared
    @State private var showingAddConfirmation = false
    @State private var showingSaveAsTemplate = false
    @State private var showingDeleteConfirmation = false
    @State private var showingServingsAdjustment = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Nutrition info
                    nutritionSection
                    
                    // Foods list
                    foodsSection
                    
                    // Usage stats
                    usageStatsSection
                    
                    // Template actions
                    templateActionsSection
                }
                .padding()
            }
            .navigationTitle(customMeal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        
                        Button("Add to Log") {
                            showingServingsAdjustment = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingServingsAdjustment) {
            CustomMealServingsView(customMeal: customMeal) { meal, adjustedFoods in
                // Add each food with adjusted servings to food log
                Task { @MainActor in
                    for adjustedFood in adjustedFoods {
                        try? foodLogManager.addFood(adjustedFood.food, servings: adjustedFood.servings, subscriptionManager: subscriptionManager)
                    }
                    // Update meal usage statistics (without adding foods again)
                    customMealManager.updateMealUsageStats(meal)
                }
            }
        }
        .alert("Save as Template", isPresented: $showingSaveAsTemplate) {
            Button("Save") {
                customMealManager.saveAsTemplate(customMeal)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save \(customMeal.name) as a template for quick access?")
        }
        .alert("Delete Custom Meal", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                customMealManager.deleteCustomMeal(customMeal)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(customMeal.name)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customMeal.category.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(customMeal.category.color)
                        .fontWeight(.semibold)
                    
                    if !customMeal.description.isEmpty {
                        Text(customMeal.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(customMeal.prepTime) min")
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
                    
                    Text("Keto Score: \(customMeal.ketoScore)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.text)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: customMeal.difficulty.icon)
                        .foregroundColor(customMeal.difficulty.color)
                        .font(.caption)
                    
                    Text(customMeal.difficulty.rawValue)
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
            Text("Nutrition (per meal)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack(spacing: 20) {
                nutritionCard("Protein", value: String(format: "%.1f", customMeal.totalProtein), unit: "g", color: AppColors.protein)
                nutritionCard("Carbs", value: String(format: "%.1f", customMeal.totalCarbs), unit: "g", color: AppColors.carbs)
                nutritionCard("Fat", value: String(format: "%.1f", customMeal.totalFat), unit: "g", color: AppColors.fat)
                nutritionCard("Calories", value: String(format: "%.0f", customMeal.totalCalories), unit: "kcal", color: AppColors.calories)
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
    
    // MARK: - Foods Section
    private var foodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foods in this meal")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            VStack(spacing: 8) {
                ForEach(customMeal.foods) { customFood in
                    CustomMealFoodDetailRow(customFood: customFood)
                }
            }
        }
    }
    
    // MARK: - Usage Stats Section
    private var usageStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Statistics")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Times Used")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(customMeal.useCount)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.accent)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(formatDate(customMeal.dateCreated))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                }
                
                if let lastUsed = customMeal.lastUsed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Used")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(formatDate(lastUsed))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Template Actions Section
    private var templateActionsSection: some View {
        VStack(spacing: 12) {
            if customMealManager.isTemplate(customMeal) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Saved as Template")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Button("Remove") {
                        customMealManager.removeTemplate(customMeal)
                    }
                    .foregroundColor(.red)
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(8)
            } else {
                Button(action: {
                    showingSaveAsTemplate = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Save as Template")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Custom Meal Food Detail Row
struct CustomMealFoodDetailRow: View {
    let customFood: CustomMealFood
    
    var body: some View {
        HStack(spacing: 12) {
            // Food icon
            Text("🍽️")
                .font(.title3)
            
            // Food info
            VStack(alignment: .leading, spacing: 2) {
                Text(customFood.food.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                
                Text("\(String(format: "%.1f", customFood.servings)) × \(customFood.food.formattedServingSize)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            // Nutrition summary
            HStack(spacing: 8) {
                nutritionBadge("P", value: String(format: "%.1f", customFood.totalNutrition.protein), color: AppColors.protein)
                nutritionBadge("C", value: String(format: "%.1f", customFood.totalNutrition.carbs), color: AppColors.carbs)
                nutritionBadge("F", value: String(format: "%.1f", customFood.totalNutrition.fat), color: AppColors.fat)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColors.background)
        .cornerRadius(8)
    }
    
    private func nutritionBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.caption)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(minWidth: 24)
    }
}

#Preview {
    CustomMealDetailView(
        customMeal: CustomMeal(
            name: "My Keto Breakfast",
            category: .breakfast,
            foods: [],
            totalNutrition: MacroNutrition(protein: 25.0, carbs: 3.0, fat: 30.0, calories: 400),
            prepTime: 5,
            difficulty: .easy,
            description: "My go-to breakfast combination",
            dateCreated: Date(),
            lastUsed: Date(),
            useCount: 15
        )
    ) { _ in }
}
