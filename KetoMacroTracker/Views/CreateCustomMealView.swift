//
//  CreateCustomMealView.swift
//  Keto Macro Tracker
//
//  View for creating and editing custom meals
//

import SwiftUI

struct CreateCustomMealView: View {
    @StateObject private var customMealManager = CustomMealManager.shared
    @EnvironmentObject var foodLogManager: FoodLogManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var quickAddManager = QuickAddManager()
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @State private var limitAlertMessage = ""
    
    @State private var builder = CustomMealBuilder()
    @State private var showingFoodSearch = false
    @State private var showingStarredFoods = false
    @State private var selectedFoodIndex: Int? = nil
    @State private var showingDeleteConfirmation = false
    @State private var foodToDelete: CustomMealFood? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Section
                    basicInfoSection
                    
                    // Foods Section
                    foodsSection
                    
                    // Nutrition Summary
                    nutritionSummarySection
                    
                    // Settings Section
                    settingsSection
                    
                    // Bottom padding to ensure all content is scrollable
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Create Custom Meal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomMeal()
                    }
                    .disabled(!builder.isValid)
                }
            }
        }
        .adaptiveSheet(isPresented: $showingFoodSearch) {
            FoodSearchView(
                foodLogManager: foodLogManager,
                quickAddManager: quickAddManager,
                onFoodSelected: { food, servings in
                    addFoodToMeal(food, servings: servings)
                }
            )
        }
        .adaptiveSheet(isPresented: $showingStarredFoods) {
            StarredFoodsPickerView(
                quickAddManager: quickAddManager,
                onFoodSelected: { food, servings in
                    addFoodToMeal(food, servings: servings)
                }
            )
        }
        .alert("Custom Meal Limit Reached", isPresented: $showingLimitAlert) {
            Button("Upgrade to Premium") {
                showingPaywall = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(limitAlertMessage)
        }
        .adaptiveSheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .alert("Delete Food", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let food = foodToDelete {
                    removeFoodFromMeal(food)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove this food from your custom meal?")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Meal Details")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Meal Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meal Name")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        TextField("e.g., My Keto Breakfast", text: $builder.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Picker("Category", selection: $builder.category) {
                            ForEach(MealCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description (Optional)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        TextField("Brief description of your meal", text: $builder.description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Foods Section
    private var foodsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Foods")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            showingStarredFoods = true
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Search") {
                            showingFoodSearch = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                if builder.foods.isEmpty {
                    emptyFoodsView
                } else {
                    foodsList
                }
            }
        }
    }
    
    private var emptyFoodsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundColor(AppColors.secondaryText)
            
            Text("No foods added yet")
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Text("Tap 'Add Food' to start building your custom meal")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var foodsList: some View {
        VStack(spacing: 12) {
            ForEach(builder.foods) { customFood in
                CustomMealFoodRow(
                    customFood: customFood,
                    onEdit: { index in
                        selectedFoodIndex = index
                        // TODO: Show edit sheet
                    },
                    onDelete: { food in
                        foodToDelete = food
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
    }
    
    // MARK: - Nutrition Summary Section
    private var nutritionSummarySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nutrition Summary")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 20) {
                    nutritionItem("Protein", value: String(format: "%.1f", builder.totalNutrition.protein), unit: "g", color: AppColors.protein)
                    nutritionItem("Carbs", value: String(format: "%.1f", builder.totalNutrition.carbs), unit: "g", color: AppColors.carbs)
                    nutritionItem("Fat", value: String(format: "%.1f", builder.totalNutrition.fat), unit: "g", color: AppColors.fat)
                    nutritionItem("Calories", value: String(format: "%.0f", builder.totalNutrition.calories), unit: "kcal", color: AppColors.calories)
                }
            }
        }
    }
    
    private func nutritionItem(_ title: String, value: String, unit: String, color: Color) -> some View {
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
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Meal Settings")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(spacing: 12) {
                    // Prep Time
                    HStack {
                        Text("Prep Time")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Picker("Prep Time", selection: $builder.prepTime) {
                            ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { time in
                                Text("\(time) min").tag(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Difficulty
                    HStack {
                        Text("Difficulty")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        Picker("Difficulty", selection: $builder.difficulty) {
                            ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                                Text(difficulty.rawValue).tag(difficulty)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func addFoodToMeal(_ food: USDAFood, servings: Double = 1.0) {
        let customFood = CustomMealFood(
            food: food,
            servings: servings,
            notes: nil
        )
        builder.foods.append(customFood)
    }
    
    private func removeFoodFromMeal(_ food: CustomMealFood) {
        builder.foods.removeAll { $0.id == food.id }
    }
    
    private func saveCustomMeal() {
        // Check premium limit before creating
        if !subscriptionManager.isPremiumActive && !customMealManager.canCreateCustomMeal(isPremium: subscriptionManager.isPremiumActive) {
            let limit = CustomMealManager.freeCustomMealLimit
            limitAlertMessage = "You've reached your limit of \(limit) custom meals. Upgrade to Premium for unlimited custom meals!"
            showingLimitAlert = true
            return
        }
        
        Task { @MainActor in
            do {
                _ = try customMealManager.createCustomMeal(
                    name: builder.name,
                    category: builder.category,
                    foods: builder.foods,
                    prepTime: builder.prepTime,
                    difficulty: builder.difficulty,
                    description: builder.description,
                    subscriptionManager: subscriptionManager
                )
                
                dismiss()
            } catch CustomMealError.limitReached(let limit, _) {
                limitAlertMessage = "You've reached your limit of \(limit) custom meals. Upgrade to Premium for unlimited custom meals!"
                showingLimitAlert = true
            } catch {
                print("❌ Error creating custom meal: \(error)")
            }
        }
    }
}

// MARK: - Custom Meal Food Row
struct CustomMealFoodRow: View {
    let customFood: CustomMealFood
    let onEdit: (Int) -> Void
    let onDelete: (CustomMealFood) -> Void
    
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
            
            // Actions
            HStack(spacing: 8) {
                Button(action: {
                    // TODO: Edit servings
                }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                }
                
                Button(action: {
                    onDelete(customFood)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
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
    CreateCustomMealView()
        .environmentObject(FoodLogManager.shared)
}
