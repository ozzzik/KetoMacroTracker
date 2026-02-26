//
//  StarredFoodsPickerView.swift
//  Keto Macro Tracker
//
//  View for selecting starred/favorite foods to add to custom meals
//

import SwiftUI

struct StarredFoodsPickerView: View {
    @ObservedObject var quickAddManager: QuickAddManager
    @Environment(\.dismiss) var dismiss
    
    let onFoodSelected: (USDAFood, Double) -> Void // food, servings
    
    @State private var searchText = ""
    @State private var showingUnitSelection = false
    @State private var selectedFood: USDAFood? = nil
    
    private var filteredItems: [QuickAddItem] {
        if searchText.isEmpty {
            return quickAddManager.quickAddItems
        } else {
            return quickAddManager.quickAddItems.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.secondaryText)
                    
                    TextField("Search starred foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(10)
                .padding()
                
                // List of starred foods
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(searchText.isEmpty ? "No Starred Foods" : "No Results")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        Text(searchText.isEmpty ? 
                             "Star foods from search to add them here" :
                             "Try a different search term")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(filteredItems) { item in
                        Button(action: {
                            // Convert to USDAFood synchronously first
                            guard let food = quickAddItemToUSDAFood(item) else {
                                print("❌ Error: Failed to convert QuickAddItem '\(item.name)' to USDAFood")
                                return
                            }
                            
                            // Validate food has valid nutrition data
                            guard food.hasValidNutritionData else {
                                print("⚠️ Warning: Food '\(item.name)' has invalid nutrition data")
                                print("   Protein: \(food.protein), Fat: \(food.fat), Carbs: \(food.totalCarbs), Calories: \(food.calories)")
                                return
                            }
                            
                            // Set selected food first (synchronously on main thread)
                            DispatchQueue.main.async {
                                selectedFood = food
                                // Small delay to ensure SwiftUI has processed the state change
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    showingUnitSelection = true
                                }
                            }
                        }) {
                            StarredFoodRow(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Starred Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { showingUnitSelection && selectedFood != nil },
                set: { newValue in
                    if !newValue {
                        showingUnitSelection = false
                        // Don't clear selectedFood immediately - let the sheet dismiss first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedFood = nil
                        }
                    }
                }
            )) {
                if let food = selectedFood, food.hasValidNutritionData {
                    UnitSelectionView(food: food) { food, amount, unit in
                        // Convert amount/unit to servings
                        let servings = convertToServings(amount: amount, unit: unit, food: food)
                        // Dismiss unit selection sheet first
                        showingUnitSelection = false
                        selectedFood = nil
                        // Then dismiss this sheet and call callback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onFoodSelected(food, servings)
                            dismiss()
                        }
                    }
                } else {
                    // This should rarely appear - only if state gets out of sync
                    NavigationView {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            Text("Unable to Load Food")
                                .font(.headline)
                            
                            Text("Please try selecting the food again.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Close") {
                                showingUnitSelection = false
                                selectedFood = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .navigationTitle("Error")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingUnitSelection = false
                                    selectedFood = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func convertToServings(amount: Double, unit: String, food: USDAFood) -> Double {
        let servingSize = food.servingSize ?? 100.0
        let servingUnit = food.servingSizeUnit ?? "g"
        
        // If same unit, just convert amount to servings
        if unit == servingUnit {
            return amount / servingSize
        }
        
        // Convert between different units (simplified conversions)
        let amountInGrams: Double
        switch unit {
        case "g":
            amountInGrams = amount
        case "oz":
            amountInGrams = amount * 28.35
        case "lb":
            amountInGrams = amount * 453.6
        case "ml", "l":
            // For liquids, assume 1ml = 1g (approximation)
            amountInGrams = unit == "l" ? amount * 1000 : amount
        case "cups":
            amountInGrams = amount * 240 // 1 cup ≈ 240ml
        case "tbsp":
            amountInGrams = amount * 15 // 1 tbsp ≈ 15ml
        case "tsp":
            amountInGrams = amount * 5 // 1 tsp ≈ 5ml
        case "servings":
            return amount // Already in servings
        default:
            amountInGrams = amount
        }
        
        // Convert to serving unit
        let servingSizeInGrams: Double
        switch servingUnit {
        case "g":
            servingSizeInGrams = servingSize
        case "oz":
            servingSizeInGrams = servingSize * 28.35
        case "lb":
            servingSizeInGrams = servingSize * 453.6
        case "ml", "l":
            servingSizeInGrams = servingUnit == "l" ? servingSize * 1000 : servingSize
        case "cups":
            servingSizeInGrams = servingSize * 240
        case "tbsp":
            servingSizeInGrams = servingSize * 15
        case "tsp":
            servingSizeInGrams = servingSize * 5
        default:
            servingSizeInGrams = servingSize
        }
        
        return amountInGrams / max(servingSizeInGrams, 1.0)
    }
    
    private func quickAddItemToUSDAFood(_ item: QuickAddItem) -> USDAFood? {
        // Use original values if they exist (non-zero), otherwise use current values
        // For original values, check if they're set (not just > 0, but actually stored)
        // If originalServingSize is 0 or originalServingSizeUnit is "serving", it's likely not set
        let hasOriginalData = item.originalServingSize > 0 && item.originalServingSizeUnit != "serving"
        
        let proteinValue = hasOriginalData && item.originalProtein >= 0 ? item.originalProtein : item.protein
        let fatValue = hasOriginalData && item.originalFat >= 0 ? item.originalFat : item.fat
        let carbsValue = hasOriginalData && item.originalTotalCarbs >= 0 ? item.originalTotalCarbs : item.totalCarbs
        let fiberValue = hasOriginalData && item.originalFiber >= 0 ? item.originalFiber : item.fiber
        let caloriesValue = hasOriginalData && item.originalCalories >= 0 ? item.originalCalories : item.calories
        let cholesterolValue = (hasOriginalData ? (item.originalCholesterol ?? item.cholesterol ?? 0) : (item.cholesterol ?? 0))
        let saturatedFatValue = (hasOriginalData ? (item.originalSaturatedFat ?? item.saturatedFat ?? 0) : (item.saturatedFat ?? 0))
        let servingSizeValue = hasOriginalData ? item.originalServingSize : 100.0
        let servingUnitValue = hasOriginalData && !item.originalServingSizeUnit.isEmpty && item.originalServingSizeUnit != "serving" ? item.originalServingSizeUnit : "g"
        
        // Validate that we have at least some nutrition data (allow 0 for individual macros, but need at least one non-zero)
        guard proteinValue >= 0 && fatValue >= 0 && carbsValue >= 0 && caloriesValue >= 0 else {
            print("❌ Error: Food '\(item.name)' has negative nutrition values")
            return nil
        }
        
        guard proteinValue > 0 || fatValue > 0 || carbsValue > 0 || caloriesValue > 0 else {
            print("❌ Error: Food '\(item.name)' has no valid nutrition data (all values are 0)")
            print("   Protein: \(item.protein), Fat: \(item.fat), Carbs: \(item.totalCarbs), Calories: \(item.calories)")
            return nil
        }
        
        let nutrients: [USDAFoodNutrient] = [
            USDAFoodNutrient(
                nutrientId: 1003,
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "G",
                value: proteinValue,
                rank: 600,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1004,
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                unitName: "G",
                value: fatValue,
                rank: 800,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1005,
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                unitName: "G",
                value: carbsValue,
                rank: 1110,
                indentLevel: 2,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1079,
                nutrientName: "Fiber, total dietary",
                nutrientNumber: "291",
                unitName: "G",
                value: fiberValue,
                rank: 1120,
                indentLevel: 2,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1008,
                nutrientName: "Energy",
                nutrientNumber: "208",
                unitName: "KCAL",
                value: caloriesValue,
                rank: 300,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1253,
                nutrientName: "Cholesterol",
                nutrientNumber: "601",
                unitName: "MG",
                value: cholesterolValue,
                rank: 1500,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1258,
                nutrientName: "Fatty acids, total saturated",
                nutrientNumber: "606",
                unitName: "G",
                value: saturatedFatValue,
                rank: 970,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            )
        ]
        
        return USDAFood(
            id: UUID(),
            fdcId: Int.random(in: 1000000...9999999),
            description: item.name,
            dataType: "QuickAdd",
            foodNutrients: nutrients,
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: item.brandName,
            ingredients: nil,
            servingSize: servingSizeValue,
            servingSizeUnit: servingUnitValue,
            foodCategory: item.category
        )
    }
}

struct StarredFoodRow: View {
    let item: QuickAddItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                
                Text(item.servingSize)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                nutritionBadge("P", value: String(format: "%.1f", item.protein), color: AppColors.protein)
                nutritionBadge("C", value: String(format: "%.1f", item.netCarbs), color: AppColors.carbs)
                nutritionBadge("F", value: String(format: "%.1f", item.fat), color: AppColors.fat)
            }
        }
        .padding(.vertical, 8)
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
        .frame(minWidth: 24)
    }
}

#Preview {
    StarredFoodsPickerView(
        quickAddManager: QuickAddManager(),
        onFoodSelected: { _, _ in }
    )
}

