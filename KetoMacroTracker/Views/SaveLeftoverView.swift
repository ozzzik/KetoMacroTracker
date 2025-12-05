//
//  SaveLeftoverView.swift
//  Keto Macro Tracker
//
//  View for saving current foods as a leftover
//

import SwiftUI

struct SaveLeftoverView: View {
    @EnvironmentObject var foodLogManager: FoodLogManager
    @StateObject private var leftoverManager = LeftoverManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var leftoverName: String = ""
    @State private var selectedFoods: Set<UUID> = []
    
    private var availableFoods: [LoggedFood] {
        foodLogManager.todaysFoods
    }
    
    private var selectedFoodsList: [LoggedFood] {
        availableFoods.filter { selectedFoods.contains($0.id) }
    }
    
    private var totalNutrition: MacroNutrition {
        let foods = selectedFoodsList
        let protein = foods.reduce(0) { $0 + $1.totalProtein }
        let carbs = foods.reduce(0) { $0 + $1.netCarbs }
        let fat = foods.reduce(0) { $0 + $1.totalFat }
        let calories = foods.reduce(0) { $0 + $1.totalCalories }
        
        return MacroNutrition(
            protein: protein,
            carbs: carbs,
            fat: fat,
            calories: calories
        )
    }
    
    private var canSave: Bool {
        !leftoverName.isEmpty && !selectedFoods.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Leftover Name")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    TextField("e.g., Meal Prep Monday", text: $leftoverName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Food selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Foods")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                        .padding(.horizontal)
                    
                    if availableFoods.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("No foods logged today")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        List(availableFoods) { food in
                            Button(action: {
                                if selectedFoods.contains(food.id) {
                                    selectedFoods.remove(food.id)
                                } else {
                                    selectedFoods.insert(food.id)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedFoods.contains(food.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFoods.contains(food.id) ? AppColors.primary : AppColors.secondaryText)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food.food.description)
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.text)
                                        
                                        Text("\(String(format: "%.1f", food.servings)) servings")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Nutrition summary
                if !selectedFoods.isEmpty {
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Summary")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.text)
                            
                            HStack(spacing: 16) {
                                nutritionBadge("Protein", value: String(format: "%.1f", totalNutrition.protein), unit: "g", color: AppColors.protein)
                                nutritionBadge("Carbs", value: String(format: "%.1f", totalNutrition.carbs), unit: "g", color: AppColors.carbs)
                                nutritionBadge("Fat", value: String(format: "%.1f", totalNutrition.fat), unit: "g", color: AppColors.fat)
                                nutritionBadge("Cal", value: String(format: "%.0f", totalNutrition.calories), unit: "", color: AppColors.calories)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Save as Leftover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLeftover()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                // Select all foods by default
                selectedFoods = Set(availableFoods.map { $0.id })
                
                // Generate default name
                if leftoverName.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    leftoverName = "Leftover - \(formatter.string(from: Date()))"
                }
            }
        }
    }
    
    private func saveLeftover() {
        let foods = selectedFoodsList.map { loggedFood in
            CustomMealFood(
                food: loggedFood.food,
                servings: loggedFood.servings,
                notes: nil
            )
        }
        
        leftoverManager.addLeftover(
            name: leftoverName,
            foods: foods,
            totalNutrition: totalNutrition
        )
        
        dismiss()
    }
    
    private func nutritionBadge(_ title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(AppTypography.caption)
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
}

#Preview {
    SaveLeftoverView()
        .environmentObject(FoodLogManager.shared)
}

