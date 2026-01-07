import SwiftUI

struct QuickAddView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var quickAddManager: QuickAddManager
    @ObservedObject var foodLogManager: FoodLogManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var historicalDataManager = HistoricalDataManager.shared
    @State private var selectedCategory = "All"
    @State private var showingAddToQuickAdd = false
    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @State private var limitAlertMessage = ""
    @State private var searchText = ""
    
    private var recentFoods: [LoggedFood] {
        historicalDataManager.getRecentFoods(days: 7, limit: 10)
    }
    
    private let predefinedCategories = ["All", "General", "Protein", "Dairy", "Vegetables", "Fruits", "Nuts", "Grains", "Beverages", "Snacks", "Breakfast", "Lunch", "Dinner", "Cooking"]
    
    // Dynamic categories that include all categories from quick add items
    private var allCategories: [String] {
        let itemCategories = Set(quickAddManager.quickAddItems.map { $0.category })
        let allCategoriesSet = Set(predefinedCategories.dropFirst()) // Remove "All" from predefined
        let combinedCategories = allCategoriesSet.union(itemCategories)
        return ["All"] + combinedCategories.sorted()
    }
    
    var filteredItems: [QuickAddItem] {
        let items: [QuickAddItem]
        if selectedCategory == "All" {
            items = quickAddManager.quickAddItems
        } else {
            items = quickAddManager.getQuickAddItemsByCategory(selectedCategory)
        }
        
        // Apply search filter
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search quick add items...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            hideKeyboard()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Recent Foods Section
                if !recentFoods.isEmpty && searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Foods")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("Last 7 days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentFoods.prefix(10), id: \.id) { loggedFood in
                                    Button(action: {
                                        // Add the food with the same serving size
                                        Task { @MainActor in
                                            do {
                                                try foodLogManager.addFood(loggedFood.food, servings: loggedFood.servings, subscriptionManager: subscriptionManager)
                                        } catch FoodLogError.dailyLimitReached(let limit, _) {
                                            limitAlertMessage = "You've reached your daily limit of \(limit) foods. Upgrade to Premium for unlimited logging!"
                                            showingLimitAlert = true
                                            } catch {
                                                print("❌ Error adding food: \(error)")
                                            }
                                        }
                                        // Don't dismiss - allow adding multiple foods
                                    }) {
                                        VStack(spacing: 6) {
                                            Text(loggedFood.food.description)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                            
                                            Text("\(String(format: "%.1f", loggedFood.servings)) serving\(loggedFood.servings == 1.0 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 120, height: 80)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allCategories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                // Quick Add Items
                if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Quick Add Items")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Add foods to your quick add list by tapping the star icon when searching for foods")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Add Sample Items") {
                            quickAddManager.createSampleQuickAddItems()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            QuickAddItemRow(
                                item: item,
                                onQuickAdd: { servings in
                                    print("🔄 QuickAddView: onQuickAdd callback received")
                                    print("  - Item: \(item.name)")
                                    print("  - Servings: \(servings)")
                                    
                                    // Validate servings
                                    guard servings > 0, servings.isFinite else {
                                        print("  - ❌ Invalid servings: \(servings)")
                                        return
                                    }
                                    
                                    // Check daily limit before adding
                                    if !subscriptionManager.isPremiumActive && !foodLogManager.canAddFoodToday(isPremium: subscriptionManager.isPremiumActive) {
                                        let limit = FoodLogManager.freeDailyFoodLimit
                                        let current = foodLogManager.todayFoodCount
                                        print("  - ⚠️ Daily limit reached: \(current)/\(limit)")
                                        limitAlertMessage = "You've reached your daily limit of \(limit) foods. Upgrade to Premium for unlimited logging!"
                                        showingLimitAlert = true
                                        return
                                    }
                                    
                                    // Add food directly
                                    print("  - ✅ Proceeding to add food to log")
                                    Task { @MainActor in
                                        do {
                                            print("  - 📞 Calling quickAddToFoodLog...")
                                            try await quickAddManager.quickAddToFoodLog(item, servings: servings, foodLogManager: foodLogManager, subscriptionManager: subscriptionManager)
                                            print("  - ✅ Food added successfully!")
                                        } catch FoodLogError.dailyLimitReached(let limit, _) {
                                            limitAlertMessage = "You've reached your daily limit of \(limit) foods. Upgrade to Premium for unlimited logging!"
                                            showingLimitAlert = true
                                        } catch {
                                            print("  - ❌ Error adding food: \(error.localizedDescription)")
                                            print("  - Error type: \(type(of: error))")
                                        }
                                    }
                                },
                                onEdit: { editedItem in
                                    quickAddManager.updateQuickAddItem(editedItem)
                                },
                                onRemove: { itemToRemove in
                                    quickAddManager.removeFromQuickAdd(itemToRemove)
                                }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let itemToRemove = filteredItems[index]
                                quickAddManager.removeFromQuickAdd(itemToRemove)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
            .alert("Daily Limit Reached", isPresented: $showingLimitAlert) {
                Button("Upgrade to Premium") {
                    showingPaywall = true
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(limitAlertMessage)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct QuickAddItemRow: View {
    let item: QuickAddItem
    let onQuickAdd: (Double) -> Void
    let onEdit: (QuickAddItem) -> Void
    let onRemove: (QuickAddItem) -> Void
    
    @State private var servingSize = "1.0"
    @State private var showingServingsInput = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(FoodIconMapper.getIcon(for: item))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let brandName = item.brandName, !brandName.isEmpty {
                        Text(brandName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !item.category.isEmpty {
                        Text(item.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Action buttons with proper spacing
                HStack(spacing: 16) {
                    // Edit button
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Add button - always prompt for amount
                    Button(action: {
                        servingSize = "1.0"
                        showingServingsInput = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Nutrition Info
            HStack(spacing: 16) {
                NutritionBadge(label: "Protein", value: item.protein, unit: "g", color: .green)
                NutritionBadge(label: "Net Carbs", value: item.netCarbs, unit: "g", color: .orange)
                NutritionBadge(label: "Fat", value: item.fat, unit: "g", color: .blue)
                NutritionBadge(label: "Cal", value: item.calories, unit: "", color: .purple)
            }
            
            // Serving Size Info
            HStack {
                Text("Serving: \(item.servingSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Tap + to add • Swipe left to delete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingServingsInput) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Add \(item.name)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Serving size: \(item.servingSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, -8)
                    
                    Text("How many servings?")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    TextField("1.0", text: $servingSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                        .font(.title)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        if let servings = Double(servingSize), servings > 0, servings.isFinite {
                            showingServingsInput = false
                            // Small delay to ensure sheet dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onQuickAdd(servings)
                            }
                        } else {
                            servingSize = "1.0"
                        }
                    }) {
                        Text("Add to Food Log")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(servingSize.isEmpty || Double(servingSize) == nil || Double(servingSize)! <= 0)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            servingSize = "1.0"
                            showingServingsInput = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditQuickAddItemView(item: item, onSave: onEdit)
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EditQuickAddItemView: View {
    @Environment(\.dismiss) var dismiss
    let item: QuickAddItem
    let onSave: (QuickAddItem) -> Void
    
    @State private var editedName = ""
    @State private var editedBrandName = ""
    @State private var selectedCategory = "General"
    @State private var customCategory = ""
    @State private var isCreatingNewCategory = false
    @State private var customServingSize = "1.0"
    @State private var customServingUnit = "servings"
    
    private let predefinedCategories = ["General", "Protein", "Dairy", "Vegetables", "Fruits", "Nuts", "Grains", "Beverages", "Snacks", "Breakfast", "Lunch", "Dinner", "Cooking"]
    
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
    
    // Computed properties for adjusted nutrition values based on original data
    private var adjustedNutritionValues: (protein: Double, netCarbs: Double, fat: Double, calories: Double) {
        let servingMultiplier = calculateServingMultiplier()
        return (
            protein: item.originalProtein * servingMultiplier,
            netCarbs: item.originalNetCarbs * servingMultiplier,
            fat: item.originalFat * servingMultiplier,
            calories: item.originalCalories * servingMultiplier
        )
    }
    
    private func calculateServingMultiplier() -> Double {
        guard let customAmount = Double(customServingSize), customAmount > 0 else { return 1.0 }
        
        let originalServingSize = item.originalServingSize
        let originalUnit = item.originalServingSizeUnit
        
        // If same unit, just divide custom by original
        if customServingUnit == originalUnit {
            return customAmount / originalServingSize
        }
        
        // Convert both to grams for comparison
        let customInGrams = convertToGrams(amount: customAmount, unit: customServingUnit)
        let originalInGrams = convertToGrams(amount: originalServingSize, unit: originalUnit)
        
        return customInGrams / originalInGrams
    }
    
    private func convertToGrams(amount: Double, unit: String) -> Double {
        switch unit.lowercased() {
        case "g", "grams":
            return amount
        case "ml", "milliliters":
            return amount // Assuming 1ml = 1g for liquids
        case "l", "liters":
            return amount * 1000
        case "cups":
            return amount * 240 // 1 cup ≈ 240ml
        case "tbsp", "tablespoons":
            return amount * 15 // 1 tbsp ≈ 15ml
        case "tsp", "teaspoons":
            return amount * 5 // 1 tsp ≈ 5ml
        case "oz", "ounces":
            return amount * 28.35 // 1 oz ≈ 28.35g
        case "lb", "pounds":
            return amount * 453.59 // 1 lb ≈ 453.59g
        case "servings":
            return amount // Keep as is for servings
        default:
            return amount
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Quick Add Item")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Item Name")
                            .font(.headline)
                        TextField("Enter item name", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                hideKeyboard()
                            }
                    }
                    
                    // Brand field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brand/Company (Optional)")
                            .font(.headline)
                        TextField("Enter brand name", text: $editedBrandName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                hideKeyboard()
                            }
                    }
                    
                    // Category selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        if isCreatingNewCategory {
                            TextField("Enter new category", text: $customCategory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    hideKeyboard()
                                }
                        } else {
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(predefinedCategories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            isCreatingNewCategory.toggle()
                            if isCreatingNewCategory {
                                customCategory = selectedCategory
                            }
                        }) {
                            Text(isCreatingNewCategory ? "Choose from list" : "Create new category")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Serving size customization
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Serving Size")
                            .font(.headline)
                        
                        HStack {
                            TextField("Amount", text: $customServingSize)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .onSubmit {
                                    hideKeyboard()
                                }
                            
                            Picker("Unit", selection: $customServingUnit) {
                                ForEach(unitOptions, id: \.0) { unit in
                                    Text(unit.1).tag(unit.0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Nutrition preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrition per \(customServingSize) \(unitOptions.first { $0.0 == customServingUnit }?.1 ?? customServingUnit)")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            NutritionBadge(label: "Protein", value: adjustedNutritionValues.protein, unit: "g", color: .green)
                            NutritionBadge(label: "Net Carbs", value: adjustedNutritionValues.netCarbs, unit: "g", color: .orange)
                            NutritionBadge(label: "Fat", value: adjustedNutritionValues.fat, unit: "g", color: .blue)
                            NutritionBadge(label: "Cal", value: adjustedNutritionValues.calories, unit: "", color: .purple)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button("Save Changes") {
                    let finalCategory = isCreatingNewCategory ? customCategory : selectedCategory
                    let finalServingSize = "\(customServingSize) \(unitOptions.first { $0.0 == customServingUnit }?.1 ?? customServingUnit)"
                    
                    let updatedItem = QuickAddItem(
                        id: item.id,
                        name: editedName,
                        protein: adjustedNutritionValues.protein,
                        fat: adjustedNutritionValues.fat,
                        totalCarbs: item.originalTotalCarbs * calculateServingMultiplier(),
                        fiber: item.originalFiber * calculateServingMultiplier(),
                        sugarAlcohols: item.originalSugarAlcohols * calculateServingMultiplier(),
                        netCarbs: adjustedNutritionValues.netCarbs,
                        calories: adjustedNutritionValues.calories,
                        servingSize: finalServingSize,
                        category: finalCategory,
                        useCount: item.useCount,
                        lastUsed: item.lastUsed,
                        createdAt: item.createdAt,
                        brandName: editedBrandName.isEmpty ? nil : editedBrandName,
                        // Keep original data unchanged
                        originalProtein: item.originalProtein,
                        originalFat: item.originalFat,
                        originalTotalCarbs: item.originalTotalCarbs,
                        originalFiber: item.originalFiber,
                        originalSugarAlcohols: item.originalSugarAlcohols,
                        originalNetCarbs: item.originalNetCarbs,
                        originalCalories: item.originalCalories,
                        originalServingSize: item.originalServingSize,
                        originalServingSizeUnit: item.originalServingSizeUnit
                    )
                    
                    onSave(updatedItem)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
        .onAppear {
            // Initialize form with current item data
            editedName = item.name
            editedBrandName = item.brandName ?? ""
            selectedCategory = item.category
            customCategory = item.category
            
            // Initialize with original serving size data
            customServingSize = String(format: "%.1f", item.originalServingSize)
            
            // Find matching unit from the original unit
            if let matchingUnit = unitOptions.first(where: { $0.0.lowercased() == item.originalServingSizeUnit.lowercased() }) {
                customServingUnit = matchingUnit.0
            } else {
                customServingUnit = "servings"
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct NutritionBadge: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 50)
    }
}

#Preview {
    QuickAddView(
        quickAddManager: QuickAddManager(),
        foodLogManager: FoodLogManager.shared
    )
}
