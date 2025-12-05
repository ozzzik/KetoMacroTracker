import SwiftUI

struct ManualFoodEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var foodLogManager: FoodLogManager
    @ObservedObject var quickAddManager: QuickAddManager
    
    @State private var foodName = ""
    @State private var amountEating = ""
    @State private var amountEatingUnit = "g"
    @State private var protein = ""
    @State private var fat = ""
    @State private var totalCarbs = ""
    @State private var fiber = ""
    @State private var sugarAlcohols = ""
    @State private var calories = ""
    @State private var nutritionDataFor = ""
    @State private var nutritionDataUnit = "g"
    @State private var addToQuickAdd = false
    @State private var selectedCategory = "General"
    @State private var quickAddServingSize = ""
    @State private var quickAddServingUnit = "g"
    
    let units = ["g", "oz", "cup", "tbsp", "tsp", "ml", "item"]
    
    let categories = ["Breakfast", "Lunch", "Dinner", "Snack", "Protein", "Vegetables", "Fruits", "Dairy", "Nuts", "Beverages", "Cooking", "General"]
    
    let onSave: (USDAFood, Double) -> Void
    
    // Optional food to pre-populate the form
    let sourceFood: USDAFood?
    
    init(foodLogManager: FoodLogManager, quickAddManager: QuickAddManager, sourceFood: USDAFood? = nil, onSave: @escaping (USDAFood, Double) -> Void) {
        self.foodLogManager = foodLogManager
        self.quickAddManager = quickAddManager
        self.sourceFood = sourceFood
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Information")) {
                    TextField("Food name", text: $foodName)
                }
                
                Section(header: Text("Amount You're Eating Now"), footer: Text("How much are you eating right now? (e.g., 50g, 1 cup)")) {
                    HStack {
                        Text("Eating")
                        Spacer()
                        TextField("50", text: $amountEating)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 70)
                        
                        Picker("Unit", selection: $amountEatingUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90)
                    }
                }
                
                Section(header: Text("Nutrition Label Data"), footer: Text("What serving size does the nutrition data below represent? (e.g., package says '56g per serving')")) {
                    HStack {
                        Text("Data is for")
                        Spacer()
                        TextField("56", text: $nutritionDataFor)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 70)
                        
                        Picker("Unit", selection: $nutritionDataUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90)
                    }
                }
                
                Section(header: Text("Macronutrients"), footer: Text("Enter the nutritional values from the label (for the serving size above)")) {
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0.0", text: $protein)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0.0", text: $fat)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Total Carbs (g)")
                        Spacer()
                        TextField("0.0", text: $totalCarbs)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Fiber (g)")
                        Spacer()
                        TextField("0.0", text: $fiber)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Sugar Alcohols (g)")
                        Spacer()
                        TextField("0.0", text: $sugarAlcohols)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                
                if !foodName.isEmpty && !totalCarbs.isEmpty {
                    Section(header: Text("Net Carbs Calculation")) {
                        let totalCarbsValue = Double(totalCarbs) ?? 0
                        let fiberValue = Double(fiber) ?? 0
                        let sugarAlcoholsValue = Double(sugarAlcohols) ?? 0
                        let netCarbs = max(0, totalCarbsValue - fiberValue - sugarAlcoholsValue)
                        
                        HStack {
                            Text("Net Carbs:")
                            Spacer()
                            Text("\(String(format: "%.1f", netCarbs))g")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section(header: Text("Quick Add (Optional)"), footer: Text("Save this food for future use. We'll convert the macros to your chosen serving size.")) {
                    Toggle("Save to Quick Add", isOn: $addToQuickAdd)
                        .tint(.blue)
                    
                    if addToQuickAdd {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("Save as")
                            Spacer()
                            TextField("100", text: $quickAddServingSize)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                            
                            Picker("Unit", selection: $quickAddServingUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 90)
                        }
                    }
                }
            }
            .navigationTitle("Add Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("🔄 ManualFoodEntryView: Save button tapped")
                        print("🔄 canSave: \(canSave)")
                        print("🔄 foodName: '\(foodName)'")
                        print("🔄 totalCarbs: '\(totalCarbs)'")
                        if let doubleValue = Double(totalCarbs) {
                            print("🔄 Double(totalCarbs): \(doubleValue)")
                        } else {
                            print("🔄 Double(totalCarbs): nil")
                        }
                        saveFood()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            print("🔄 ManualFoodEntryView: View appeared")
            populateFromSourceFood()
        }
        .onDisappear {
            print("🔄 ManualFoodEntryView: View disappeared")
        }
    }
    
    private var canSave: Bool {
        !foodName.isEmpty && 
        !totalCarbs.isEmpty &&
        Double(totalCarbs) != nil
    }
    
    private func populateFromSourceFood() {
        guard let sourceFood = sourceFood else {
            print("🔄 No source food provided - using defaults")
            return
        }
        
        print("🔄 Populating form from source food: \(sourceFood.description)")
        
        // Pre-populate food name
        foodName = sourceFood.description
        
        // Pre-populate serving size information
        if let servingSize = sourceFood.servingSize, let servingUnit = sourceFood.servingSizeUnit {
            // For USDA foods, the servingSize is typically 100g, but the macros might be for a different amount
            // We need to determine what the macros actually represent
            
            // Check if this looks like a 100g reference (common for USDA database)
            if servingSize == 100.0 && servingUnit == "g" {
                // This is likely a 100g reference serving from USDA
                nutritionDataFor = "100"
                nutritionDataUnit = "g"
                quickAddServingSize = "100"
                quickAddServingUnit = "g"
                
                // Set amount eating to a reasonable default (like 1/4 of the reference)
                amountEating = "25"
                amountEatingUnit = "g"
                
                print("🔄 Detected USDA 100g reference - set nutrition data for 100g")
            } else {
                // Use the actual serving size from the food
                nutritionDataFor = String(format: "%.0f", servingSize)
                nutritionDataUnit = servingUnit
                quickAddServingSize = String(format: "%.0f", servingSize)
                quickAddServingUnit = servingUnit
                
                // Set amount eating to match the serving size
                amountEating = String(format: "%.0f", servingSize)
                amountEatingUnit = servingUnit
                
                print("🔄 Set serving size: \(servingSize)\(servingUnit)")
            }
        }
        
        // Pre-populate nutrition data
        protein = String(format: "%.1f", sourceFood.protein)
        fat = String(format: "%.1f", sourceFood.fat)
        totalCarbs = String(format: "%.1f", sourceFood.totalCarbs)
        fiber = String(format: "%.1f", sourceFood.fiber)
        sugarAlcohols = String(format: "%.1f", sourceFood.sugarAlcohols)
        calories = String(format: "%.0f", sourceFood.calories)
        
        // Enable Quick Add by default when pre-populated
        addToQuickAdd = true
        
        print("🔄 Form populated with:")
        print("   Name: \(foodName)")
        print("   Nutrition data for: \(nutritionDataFor)\(nutritionDataUnit)")
        print("   Quick Add serving: \(quickAddServingSize)\(quickAddServingUnit)")
        print("   Amount eating: \(amountEating)\(amountEatingUnit)")
        print("   Protein: \(protein)g, Carbs: \(totalCarbs)g, Fat: \(fat)g")
    }
    
    private func saveFood() {
        print("🔄 ManualFoodEntryView: saveFood() called")
        print("🔄 Food name: \(foodName)")
        
        // Get the three measurements
        let eating = Double(amountEating) ?? 50.0
        let eatingUnit = amountEatingUnit
        let labelSize = Double(nutritionDataFor) ?? 56.0
        let labelUnit = nutritionDataUnit
        let quickAddSize = Double(quickAddServingSize) ?? 100.0
        let quickAddUnit = quickAddServingUnit
        
        print("🔄 Eating: \(eating)\(eatingUnit)")
        print("🔄 Label data for: \(labelSize)\(labelUnit)")
        print("🔄 Quick Add serving: \(quickAddSize)\(quickAddUnit)")
        
        // Step 1: Convert label macros to Quick Add serving size
        // Calculate ratio: quickAddSize / labelSize
        let conversionRatio: Double
        if labelUnit == quickAddUnit && labelSize > 0 {
            conversionRatio = quickAddSize / labelSize
            print("🔄 Conversion ratio: \(quickAddSize) / \(labelSize) = \(conversionRatio)")
        } else {
            conversionRatio = 1.0
            print("⚠️ Units don't match or invalid label size - using 1:1 ratio")
        }
        
        // Convert macros from label serving to Quick Add serving
        let convertedProtein = (Double(protein) ?? 0) * conversionRatio
        let convertedFat = (Double(fat) ?? 0) * conversionRatio
        let convertedCarbs = (Double(totalCarbs) ?? 0) * conversionRatio
        let convertedFiber = (Double(fiber) ?? 0) * conversionRatio
        let convertedSugarAlcohols = (Double(sugarAlcohols) ?? 0) * conversionRatio
        let convertedCalories = (Double(calories) ?? 0) * conversionRatio
        
        print("🔄 Converted macros (per \(quickAddSize)\(quickAddUnit)):")
        print("   Protein: \(convertedProtein)g, Carbs: \(convertedCarbs)g, Fat: \(convertedFat)g")
        
        // Create food with Quick Add serving size and converted macros
        let food = USDAFood(
            id: UUID(),
            fdcId: Int.random(in: 1000000...9999999),
            description: foodName,
            dataType: "Manual Entry",
            foodNutrients: createNutrients(
                protein: convertedProtein,
                fat: convertedFat,
                carbs: convertedCarbs,
                fiber: convertedFiber,
                sugarAlcohols: convertedSugarAlcohols,
                calories: convertedCalories
            ),
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: nil,
            ingredients: nil,
            servingSize: quickAddSize,
            servingSizeUnit: quickAddUnit,
            foodCategory: "Manual Entry"
        )
        
        print("🔄 Created USDAFood: \(food.description)")
        print("🔄 Food protein: \(food.protein), carbs: \(food.totalCarbs), fat: \(food.fat)")
        
        // Step 2: Add to Quick Add if toggle is enabled
        if addToQuickAdd {
            print("🔄 Adding to Quick Add with category: \(selectedCategory)")
            quickAddManager.addToQuickAdd(food, category: selectedCategory)
        }
        
        // Step 3: Calculate how many Quick Add servings to log for what you ate
        let servingsToLog: Double
        if eatingUnit == quickAddUnit && quickAddSize > 0 {
            servingsToLog = eating / quickAddSize
            print("🔄 Logging: \(eating)\(eatingUnit) / \(quickAddSize)\(quickAddUnit) = \(servingsToLog) servings")
        } else {
            servingsToLog = 1.0
            print("⚠️ Units don't match - defaulting to 1.0 serving")
        }
        
        print("🔄 Final log: \(servingsToLog) servings")
        
        // Pass the food AND number of servings to the callback
        onSave(food, servingsToLog)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func createNutrients(protein proteinValue: Double? = nil, 
                                 fat fatValue: Double? = nil, 
                                 carbs carbsValue: Double? = nil, 
                                 fiber fiberValue: Double? = nil, 
                                 sugarAlcohols sugarAlcoholsValue: Double? = nil, 
                                 calories caloriesValue: Double? = nil) -> [USDAFoodNutrient] {
        var nutrients: [USDAFoodNutrient] = []
        
        // Use provided values or parse from text fields
        let proteinVal = proteinValue ?? Double(protein) ?? 0
        let fatVal = fatValue ?? Double(fat) ?? 0
        let carbsVal = carbsValue ?? Double(totalCarbs) ?? 0
        let fiberVal = fiberValue ?? Double(fiber) ?? 0
        let sugarAlcoholsVal = sugarAlcoholsValue ?? Double(sugarAlcohols) ?? 0
        let caloriesVal = caloriesValue ?? Double(calories) ?? 0
        
        // Protein (ID: 1003)
        if proteinVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1003,
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "g",
                value: proteinVal,
                rank: 100,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        // Fat (ID: 1004)
        if fatVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1004,
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                unitName: "g",
                value: fatVal,
                rank: 200,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        // Total Carbs (ID: 1005)
        if carbsVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1005,
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                unitName: "g",
                value: carbsVal,
                rank: 300,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        // Fiber (ID: 1079)
        if fiberVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1079,
                nutrientName: "Fiber, total dietary",
                nutrientNumber: "291",
                unitName: "g",
                value: fiberVal,
                rank: 400,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        // Sugar Alcohols (ID: 1017)
        if sugarAlcoholsVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1017,
                nutrientName: "Alcohol, sugar",
                nutrientNumber: "243",
                unitName: "g",
                value: sugarAlcoholsVal,
                rank: 500,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        // Calories (ID: 1008)
        if caloriesVal > 0 {
            nutrients.append(USDAFoodNutrient(
                nutrientId: 1008,
                nutrientName: "Energy",
                nutrientNumber: "208",
                unitName: "kcal",
                value: caloriesVal,
                rank: 50,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: 0,
                derivationCode: nil,
                derivationDescription: nil
            ))
        }
        
        return nutrients
    }
}

#Preview {
    ManualFoodEntryView(foodLogManager: FoodLogManager.shared, quickAddManager: QuickAddManager(), sourceFood: nil) { _, _ in }
}
