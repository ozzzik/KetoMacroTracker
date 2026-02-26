import SwiftUI

struct QuickAddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    let food: USDAFood
    let quickAddManager: QuickAddManager
    
    @State private var selectedCategory = "General"
    @State private var customCategory = ""
    @State private var isCreatingNewCategory = false
    @State private var customServingSize = "1.0"
    @State private var customServingUnit = "servings"
    
    private let predefinedCategories = ["General", "Protein", "Dairy", "Vegetables", "Fruits", "Nuts", "Grains", "Beverages", "Snacks"]
    
    private let unitOptions = [
        ("servings", "Servings"),
        ("g", "Grams"),
        ("ml", "Milliliters"),
        ("l", "Liters"),
        ("cups", "Cups"),
        ("tbsp", "Tablespoons"),
        ("tsp", "Teaspoons"),
        ("oz", "Ounces"),
        ("lb", "Pounds")
    ]
    
    // Computed properties for adjusted nutrition values
    private var adjustedNutritionValues: (protein: Double, netCarbs: Double, fat: Double, calories: Double) {
        let servingMultiplier = calculateServingMultiplier()
        return (
            protein: food.protein * servingMultiplier,
            netCarbs: food.netCarbs * servingMultiplier,
            fat: food.fat * servingMultiplier,
            calories: food.calories * servingMultiplier
        )
    }
    
    private func calculateServingMultiplier() -> Double {
        guard let customAmount = Double(customServingSize), customAmount > 0 else { return 1.0 }
        
        let originalServingSize = food.servingSize ?? 100.0
        let originalUnit = food.servingSizeUnit ?? "g"
        
        // If same unit, just divide custom by original
        if customServingUnit == originalUnit {
            return customAmount / originalServingSize
        }
        
        // Convert both to grams for comparison
        let customInGrams = convertToGrams(customAmount, unit: customServingUnit)
        let originalInGrams = convertToGrams(originalServingSize, unit: originalUnit)
        
        return customInGrams / originalInGrams
    }
    
    private func convertToGrams(_ amount: Double, unit: String) -> Double {
        switch unit {
        case "g": return amount
        case "ml", "l": return amount * (unit == "l" ? 1000 : 1) // Rough approximation for liquids
        case "cups": return amount * 240
        case "tbsp": return amount * 15
        case "tsp": return amount * 5
        case "oz": return amount * 28.35
        case "lb": return amount * 453.6
        case "servings": return amount * (food.servingSize ?? 100)
        default: return amount
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
                // Food Info Header
                VStack(spacing: 12) {
                    Text(FoodIconMapper.getIcon(for: food))
                        .font(.system(size: 48))
                    
                    Text(food.description)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if let brand = food.brandName {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Serving size info
                    Text("Per \(customServingSize) \(unitOptions.first { $0.0 == customServingUnit }?.1 ?? customServingUnit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Nutrition preview
                    HStack(spacing: 16) {
                        NutritionBadge(label: "Protein", value: adjustedNutritionValues.protein, unit: "g", color: .green)
                        NutritionBadge(label: "Net Carbs", value: adjustedNutritionValues.netCarbs, unit: "g", color: .orange)
                        NutritionBadge(label: "Fat", value: adjustedNutritionValues.fat, unit: "g", color: .blue)
                        NutritionBadge(label: "Cal", value: adjustedNutritionValues.calories, unit: "", color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Category Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                    
                    if isCreatingNewCategory {
                        HStack {
                            TextField("New category name", text: $customCategory)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    hideKeyboard()
                                }
                            
                            Button("Cancel") {
                                isCreatingNewCategory = false
                                customCategory = ""
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(predefinedCategories, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        Text(category)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }
                                
                                Button(action: {
                                    isCreatingNewCategory = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("New")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Custom Serving Size
                VStack(alignment: .leading, spacing: 12) {
                    Text("Regular Serving Size")
                        .font(.headline)
                    
                    Text("Set your typical serving size for this food. When you add it to your log, it will default to 1.0 of this serving.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("1.0", text: $customServingSize)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .onSubmit {
                                hideKeyboard()
                            }
                        
                        Menu {
                            ForEach(unitOptions, id: \.0) { unit in
                                Button(unit.1) {
                                    customServingUnit = unit.0
                                }
                            }
                        } label: {
                            HStack {
                                Text(unitOptions.first { $0.0 == customServingUnit }?.1 ?? customServingUnit)
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Add to Quick Add Button
                Button("Add to Quick Add") {
                    let finalCategory = isCreatingNewCategory && !customCategory.isEmpty ? customCategory : selectedCategory
                    
                    // Create adjusted nutrients based on the custom serving size
                    let multiplier = calculateServingMultiplier()
                    let adjustedNutrients = food.foodNutrients?.map { (nutrient: USDAFoodNutrient) in
                        USDAFoodNutrient(
                            nutrientId: nutrient.nutrientId,
                            nutrientName: nutrient.nutrientName,
                            nutrientNumber: nutrient.nutrientNumber,
                            unitName: nutrient.unitName,
                            value: (nutrient.value ?? 0) * multiplier,
                            rank: nutrient.rank,
                            indentLevel: nutrient.indentLevel,
                            foodNutrientId: nutrient.foodNutrientId,
                            dataPoints: nutrient.dataPoints,
                            derivationCode: nutrient.derivationCode,
                            derivationDescription: nutrient.derivationDescription
                        )
                    } ?? []
                    
                    // Create a custom USDAFood with the user's serving size and adjusted nutrition
                    let customFood = USDAFood(
                        id: UUID(),
                        fdcId: food.fdcId,
                        description: food.description,
                        dataType: food.dataType,
                        foodNutrients: adjustedNutrients,
                        gtinUpc: food.gtinUpc,
                        publishedDate: food.publishedDate,
                        brandOwner: food.brandOwner,
                        brandName: food.brandName,
                        ingredients: food.ingredients,
                        servingSize: Double(customServingSize) ?? 1.0,
                        servingSizeUnit: customServingUnit,
                        foodCategory: food.foodCategory
                    )
                    
                    print("🔧 QuickAddCategoryView: About to call addToQuickAdd")
                    print("🔧 QuickAddManager instance: \(Unmanaged.passUnretained(quickAddManager).toOpaque())")
                    // Pass the original food as originalFood to preserve original values
                    quickAddManager.addToQuickAdd(customFood, category: finalCategory, originalFood: food)
                    print("🔧 QuickAddCategoryView: addToQuickAdd completed")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled((isCreatingNewCategory && customCategory.isEmpty) || Double(customServingSize) == nil)
            }
            .padding()
            .navigationTitle("Add to Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                populateFromFood()
            }
    }
    
    private func populateFromFood() {
        print("🔄 QuickAddCategoryView: Populating from food: \(food.description)")
        
        // Always default to 100g to match the search screen, which shows "Nutrition per 100g"
        // and "× 100g". USDA and Open Food Facts report nutrients per 100g; the API may also
        // return a different "serving" (e.g. 151g) which would confuse users who saw 100g on search.
        customServingSize = "100"
        customServingUnit = "g"
        print("🔄 Default serving size to 100g to match search screen")
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    QuickAddCategoryView(
        food: USDAFood(
            id: UUID(),
            fdcId: 123,
            description: "Sample Food",
            dataType: "Sample",
            foodNutrients: [],
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: "Sample Brand",
            ingredients: nil,
            servingSize: 100,
            servingSizeUnit: "g",
            foodCategory: "Sample"
        ),
        quickAddManager: QuickAddManager()
    )
}
