import Foundation

struct QuickAddItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var protein: Double
    var fat: Double
    var totalCarbs: Double
    var fiber: Double
    var sugarAlcohols: Double
    var netCarbs: Double
    var calories: Double
    var servingSize: String
    var category: String
    var useCount: Int
    var lastUsed: Date?
    var createdAt: Date
    var brandName: String? // Brand/vendor information
    
    // Cholesterol and saturated fat (optional for backward compatibility; existing items will have nil → 0)
    var cholesterol: Double? = nil
    var saturatedFat: Double? = nil
    
    // Original USDA food data for recalculation (optional for backward compatibility)
    var originalProtein: Double = 0.0
    var originalFat: Double = 0.0
    var originalTotalCarbs: Double = 0.0
    var originalFiber: Double = 0.0
    var originalSugarAlcohols: Double = 0.0
    var originalNetCarbs: Double = 0.0
    var originalCalories: Double = 0.0
    var originalServingSize: Double = 1.0
    var originalServingSizeUnit: String = "serving"
    var originalCholesterol: Double? = nil
    var originalSaturatedFat: Double? = nil
}

class QuickAddManager: ObservableObject {
    @Published var quickAddItems: [QuickAddItem] = []
    
    private let userDefaultsKey = "QuickAddItems"
    private var isAddingToQuickAdd = false
    
    init() {
        // Load items synchronously to ensure they're available immediately
        loadQuickAddItems()
        
        // Only create sample items if we truly have no items
        // This check happens after synchronous load, so it's safe
        if quickAddItems.isEmpty {
            print("📱 Quick Add items list is empty after load, creating sample items")
            createSampleQuickAddItems()
        }
        
        // Fix serving sizes after a brief delay to ensure UI is ready
        DispatchQueue.main.async { [weak self] in
            self?.fixServingSizes()
        }
    }
    
    func loadQuickAddItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📱 No Quick Add items found in UserDefaults")
            return
        }
        
        do {
            let items = try JSONDecoder().decode([QuickAddItem].self, from: data)
            
            // Migrate old items that don't have original data or brandName
            let migratedItems = items.map { item in
                var migratedItem = item
                
                // Check if this is an old item without original data
                if item.originalServingSize == 0.0 && item.originalServingSizeUnit == "serving" && item.originalProtein == 0.0 {
                    // Migrate old item by using current values as original
                    migratedItem.originalProtein = item.protein
                    migratedItem.originalFat = item.fat
                    migratedItem.originalTotalCarbs = item.totalCarbs
                    migratedItem.originalFiber = item.fiber
                    migratedItem.originalSugarAlcohols = item.sugarAlcohols
                    migratedItem.originalNetCarbs = item.netCarbs
                    migratedItem.originalCalories = item.calories
                    migratedItem.originalServingSize = 1.0
                    migratedItem.originalServingSizeUnit = "serving"
                    print("🔧 Migrated item: \(item.name)")
                }
                
                // Ensure brandName is set (for backward compatibility)
                if migratedItem.brandName == nil {
                    migratedItem.brandName = nil // Keep as nil for now
                }
                
                return migratedItem
            }
            
            let sortedItems = migratedItems.sorted { item1, item2 in
                // Most recently used first (LRU order: least recently used at bottom)
                if let date1 = item1.lastUsed, let date2 = item2.lastUsed {
                    if date1 != date2 { return date1 > date2 }
                } else if item1.lastUsed != nil { return true }
                else if item2.lastUsed != nil { return false }
                if item1.useCount != item2.useCount { return item1.useCount > item2.useCount }
                return item1.createdAt > item2.createdAt
            }
            
            // Update synchronously - must be on main thread for @Published property
            // Since QuickAddManager is created as @StateObject, init runs on main thread
            assert(Thread.isMainThread, "QuickAddManager.init must run on main thread")
            quickAddItems = sortedItems
            
            // Save migrated items if any changes were made (but don't reload to avoid race conditions)
            if migratedItems != items {
                // Save without reloading - @Published will update UI
                let dataToSave = try? JSONEncoder().encode(sortedItems)
                if let data = dataToSave {
                    UserDefaults.standard.set(data, forKey: userDefaultsKey)
                    UserDefaults.standard.synchronize()
                }
            }
            
            print("📱 Loaded \(quickAddItems.count) Quick Add items:")
            for item in quickAddItems {
                print("  - \(item.name) (Category: \(item.category))")
            }
        } catch {
            print("❌ Failed to decode Quick Add items: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            // Don't clear data on decode error - keep existing items if possible
            // Only clear if we have no items at all
            if quickAddItems.isEmpty {
                print("⚠️ No items loaded and decode failed, starting fresh")
            }
        }
    }
    
    func saveQuickAddItems() {
        // Ensure we're on main thread for @Published property access
        let itemsToSave = quickAddItems
        
        do {
            let data = try JSONEncoder().encode(itemsToSave)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize() // Force immediate write to disk
            print("💾 Saved \(itemsToSave.count) Quick Add items to persistent storage")
        } catch {
            print("❌ Failed to save Quick Add items: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            // Don't clear data on save error - keep existing items
        }
    }
    
    func addToQuickAdd(_ food: USDAFood, category: String = "General", originalFood: USDAFood? = nil) {
        print("🔧 QuickAddManager.addToQuickAdd called:")
        print("  - Food: \(food.description)")
        print("  - Category: \(category)")
        print("  - Original food provided: \(originalFood != nil)")
        print("  - Current item count: \(quickAddItems.count)")
        print("  - Manager instance: \(Unmanaged.passUnretained(self).toOpaque())")
        
        // Prevent multiple simultaneous additions
        guard !isAddingToQuickAdd else {
            print("⚠️ Already adding to Quick Add, ignoring duplicate request")
            return
        }
        
        isAddingToQuickAdd = true
        print("🚀 Adding to Quick Add: \(food.description) in category: \(category)")
        
        // Check if item already exists
        if let existingIndex = quickAddItems.firstIndex(where: { $0.name == food.description && $0.category == category }) {
            // Update existing item
            quickAddItems[existingIndex].useCount += 1
            quickAddItems[existingIndex].lastUsed = Date()
        } else {
            // Create new item with user's custom serving size information
            let servingSizeText: String
            if let size = food.servingSize, let unit = food.servingSizeUnit {
                servingSizeText = "\(String(format: "%.1f", size))\(unit)"
            } else {
                servingSizeText = "1 serving"
            }
            
            // Use originalFood values if provided, otherwise use current food values
            // This allows preserving the original values before conversion
            let originalProtein = originalFood?.protein ?? food.protein
            let originalFat = originalFood?.fat ?? food.fat
            let originalTotalCarbs = originalFood?.totalCarbs ?? food.totalCarbs
            let originalFiber = originalFood?.fiber ?? food.fiber
            let originalSugarAlcohols = originalFood?.sugarAlcohols ?? food.sugarAlcohols
            let originalNetCarbs = originalFood?.netCarbs ?? food.netCarbs
            let originalCalories = originalFood?.calories ?? food.calories
            let originalServingSize = originalFood?.servingSize ?? food.servingSize ?? 100.0
            let originalServingSizeUnit = originalFood?.servingSizeUnit ?? food.servingSizeUnit ?? "g"
            let originalCholesterolVal = originalFood?.cholesterol ?? food.cholesterol
            let originalSaturatedFatVal = originalFood?.saturatedFat ?? food.saturatedFat
            
            print("🔄 Storing original values: servingSize=\(originalServingSize)\(originalServingSizeUnit), protein=\(originalProtein)g")
            print("🔄 Storing current values: servingSize=\(food.servingSize ?? 0)\(food.servingSizeUnit ?? ""), protein=\(food.protein)g")
            
            let newItem = QuickAddItem(
                name: food.description,
                protein: food.protein,
                fat: food.fat,
                totalCarbs: food.totalCarbs,
                fiber: food.fiber,
                sugarAlcohols: food.sugarAlcohols,
                netCarbs: food.netCarbs,
                calories: food.calories,
                servingSize: servingSizeText,
                category: category,
                useCount: 1,
                lastUsed: Date(),
                createdAt: Date(),
                brandName: food.brandName, // Include brand information
                cholesterol: food.cholesterol > 0 ? food.cholesterol : nil,
                saturatedFat: food.saturatedFat > 0 ? food.saturatedFat : nil,
                // Store original USDA data (before conversion)
                originalProtein: originalProtein,
                originalFat: originalFat,
                originalTotalCarbs: originalTotalCarbs,
                originalFiber: originalFiber,
                originalSugarAlcohols: originalSugarAlcohols,
                originalNetCarbs: originalNetCarbs,
                originalCalories: originalCalories,
                originalServingSize: originalServingSize,
                originalServingSizeUnit: originalServingSizeUnit,
                originalCholesterol: originalCholesterolVal > 0 ? originalCholesterolVal : nil,
                originalSaturatedFat: originalSaturatedFatVal > 0 ? originalSaturatedFatVal : nil
            )
            quickAddItems.append(newItem)
        }
        
        saveQuickAddItems()
        // Don't reload - @Published property will update UI automatically
        print("✅ Quick Add updated successfully. Total items: \(quickAddItems.count)")
        
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            // Force SwiftUI to observe the change
            self.objectWillChange.send()
        }
        
        // Reset the flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAddingToQuickAdd = false
        }
    }
    
    func quickAddToFoodLog(_ quickAddItem: QuickAddItem, servings: Double = 1.0, foodLogManager: FoodLogManager, subscriptionManager: SubscriptionManager? = nil) async throws {
        print("🔄 QuickAddManager.quickAddToFoodLog called:")
        print("  - Item: \(quickAddItem.name)")
        print("  - Servings: \(servings)")
        print("  - FoodLogManager: \(Unmanaged.passUnretained(foodLogManager).toOpaque())")
        
        // Update use count and last used on main thread, then re-sort by usage (most recent first)
        await MainActor.run {
            if let index = quickAddItems.firstIndex(where: { $0.id == quickAddItem.id }) {
                quickAddItems[index].useCount += 1
                quickAddItems[index].lastUsed = Date()
                sortByUsage()
                saveQuickAddItems()
            }
        }
        
        // Create a USDAFood-like object for the food log with proper nutrients
        let nutrients: [USDAFoodNutrient] = [
            USDAFoodNutrient(
                nutrientId: 1003, // Protein
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "G",
                value: quickAddItem.protein,
                rank: 600,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1004, // Fat
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                unitName: "G",
                value: quickAddItem.fat,
                rank: 800,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1005, // Carbs
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                unitName: "G",
                value: quickAddItem.totalCarbs,
                rank: 1110,
                indentLevel: 2,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1079, // Fiber
                nutrientName: "Fiber, total dietary",
                nutrientNumber: "291",
                unitName: "G",
                value: quickAddItem.fiber,
                rank: 1120,
                indentLevel: 2,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1008, // Calories
                nutrientName: "Energy",
                nutrientNumber: "208",
                unitName: "KCAL",
                value: quickAddItem.calories,
                rank: 300,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1253, // Cholesterol
                nutrientName: "Cholesterol",
                nutrientNumber: "601",
                unitName: "MG",
                value: quickAddItem.cholesterol ?? 0,
                rank: 1500,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDAFoodNutrient(
                nutrientId: 1258, // Saturated Fat
                nutrientName: "Fatty acids, total saturated",
                nutrientNumber: "606",
                unitName: "G",
                value: quickAddItem.saturatedFat ?? 0,
                rank: 970,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            )
        ]
        
        let usdaFood = USDAFood(
            id: UUID(),
            fdcId: Int.random(in: 1000000...9999999),
            description: quickAddItem.name,
            dataType: "QuickAdd",
            foodNutrients: nutrients,
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: nil,
            ingredients: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            foodCategory: quickAddItem.category
        )
        
        // Add to food log using the existing manager
        print("🔄 Calling foodLogManager.addFood with:")
        print("  - Food: \(usdaFood.description)")
        print("  - Servings: \(servings)")
        print("  - Protein: \(usdaFood.protein)g, Carbs: \(usdaFood.totalCarbs)g, Fat: \(usdaFood.fat)g")
        
        // Ensure we're on the main actor for UI updates (required for @Published properties)
        // FoodLogManager is @MainActor, so we must call from main actor
        return try await MainActor.run {
            print("  - Adding food on main actor")
            try foodLogManager.addFood(usdaFood, servings: servings, subscriptionManager: subscriptionManager)
            print("✅ quickAddToFoodLog completed - food added to log")
        }
    }
    
    func removeQuickAddItem(_ item: QuickAddItem) {
        quickAddItems.removeAll { $0.id == item.id }
        saveQuickAddItems()
        // Don't reload - @Published will update UI automatically
    }
    
    /// Sort quick add items by usage: most recently used first
    private func sortByUsage() {
        quickAddItems.sort { item1, item2 in
            if let date1 = item1.lastUsed, let date2 = item2.lastUsed {
                if date1 != date2 { return date1 > date2 }
            } else if item1.lastUsed != nil { return true }
            else if item2.lastUsed != nil { return false }
            if item1.useCount != item2.useCount { return item1.useCount > item2.useCount }
            return item1.createdAt > item2.createdAt
        }
    }

    func getQuickAddItemsByCategory(_ category: String) -> [QuickAddItem] {
        return quickAddItems.filter { $0.category == category }
    }
    
    // Fix existing items with incorrect serving size format
    func fixServingSizes() {
        var needsUpdate = false
        
        for i in 0..<quickAddItems.count {
            let item = quickAddItems[i]
            
            // Check if serving size is generic "1 serving" or just a unit without a number
            if item.servingSize == "1 serving" || (item.servingSize.count <= 3 && item.servingSize.allSatisfy({ !$0.isNumber })) {
                // Try to extract serving info from the food name
                let newServingSize = extractServingFromName(item.name)
                quickAddItems[i].servingSize = newServingSize
                needsUpdate = true
                print("🔧 Fixed serving size for \(item.name): '\(item.servingSize)' → '\(newServingSize)'")
            }
        }
        
        if needsUpdate {
            saveQuickAddItems()
            // Don't reload - @Published will update UI automatically
        }
    }
    
    // Extract serving size information from food name
    private func extractServingFromName(_ name: String) -> String {
        let lowercasedName = name.lowercased()
        
        // Check for specific patterns in the name
        if lowercasedName.contains("2 large") || lowercasedName.contains("(2 large)") {
            return "2 eggs"
        } else if lowercasedName.contains("1 medium") || lowercasedName.contains("(1 medium)") {
            return "1 avocado"
        } else if lowercasedName.contains("1 cup") || lowercasedName.contains("(1 cup)") {
            return "1 cup"
        } else if lowercasedName.contains("6oz") || lowercasedName.contains("(6oz)") {
            return "6 oz"
        } else if lowercasedName.contains("1 oz") || lowercasedName.contains("(1 oz)") {
            return "1 oz"
        } else if lowercasedName.contains("1 tbsp") || lowercasedName.contains("(1 tbsp)") {
            return "1 tbsp"
        } else if lowercasedName.contains("unsweetened almond milk") {
            return "1 cup"
        } else if lowercasedName.contains("egg whites") {
            return "1 cup"
        } else if lowercasedName.contains("blackberries") || lowercasedName.contains("framboises") {
            return "1 cup"
        } else if lowercasedName.contains("maple honey turkey") {
            return "2 oz"
        } else if lowercasedName.contains("cheese, cheddar") {
            return "1 oz"
        } else if lowercasedName.contains("chunk light tuna") {
            return "1 can"
        }
        
        // Default fallback
        return "1 serving"
    }
    
    func getMostUsedItems(limit: Int = 10) -> [QuickAddItem] {
        return Array(quickAddItems.prefix(limit))
    }
    
    func getRecentlyUsedItems(limit: Int = 10) -> [QuickAddItem] {
        let sortedItems = quickAddItems.sorted { item1, item2 in
            guard let date1 = item1.lastUsed, let date2 = item2.lastUsed else { return false }
            return date1 > date2
        }
        return Array(sortedItems.prefix(limit))
    }
    
    // MARK: - Edit and Remove Functions
    func removeFromQuickAdd(_ item: QuickAddItem) {
        quickAddItems.removeAll { $0.id == item.id }
        saveQuickAddItems()
        print("🗑️ Removed \(item.name) from Quick Add")
    }
    
    func updateQuickAddItem(_ item: QuickAddItem) {
        if let index = quickAddItems.firstIndex(where: { $0.id == item.id }) {
            quickAddItems[index] = item
            saveQuickAddItems()
            print("✏️ Updated \(item.name) in Quick Add")
        }
    }
    
    // Method to clear all Quick Add items (useful for testing or resetting)
    func clearAllQuickAddItems() {
        quickAddItems.removeAll()
        saveQuickAddItems()
        // Don't reload - @Published will update UI automatically
        print("🗑️ Cleared all Quick Add items")
    }
    
    // Predefined categories with sample items
    func createSampleQuickAddItems() {
        let sampleItems: [(name: String, protein: Double, fat: Double, carbs: Double, fiber: Double, calories: Double, servingSize: String, category: String)] = [
            ("Eggs (2 large)", 12.0, 10.0, 1.0, 0.0, 140.0, "2 eggs", "Breakfast"),
            ("Avocado (1 medium)", 3.0, 21.0, 12.0, 9.0, 240.0, "1 avocado", "Breakfast"),
            ("Greek Yogurt (1 cup)", 20.0, 0.0, 6.0, 0.0, 100.0, "1 cup", "Breakfast"),
            ("Chicken Breast (6oz)", 53.0, 6.0, 0.0, 0.0, 280.0, "6 oz", "Lunch"),
            ("Broccoli (1 cup)", 3.0, 0.0, 6.0, 2.5, 25.0, "1 cup", "Lunch"),
            ("Salmon (6oz)", 39.0, 22.0, 0.0, 0.0, 350.0, "6 oz", "Dinner"),
            ("Spinach (1 cup)", 1.0, 0.0, 1.0, 1.0, 7.0, "1 cup", "Dinner"),
            ("Almonds (1 oz)", 6.0, 14.0, 6.0, 4.0, 160.0, "1 oz", "Snack"),
            ("Cheese (1 oz)", 7.0, 9.0, 1.0, 0.0, 110.0, "1 oz", "Snack"),
            ("Olive Oil (1 tbsp)", 0.0, 14.0, 0.0, 0.0, 120.0, "1 tbsp", "Cooking")
        ]
        
        for item in sampleItems {
            let quickAddItem = QuickAddItem(
                name: item.name,
                protein: item.protein,
                fat: item.fat,
                totalCarbs: item.carbs,
                fiber: item.fiber,
                sugarAlcohols: 0.0,
                netCarbs: item.carbs - item.fiber,
                calories: item.calories,
                servingSize: item.servingSize,
                category: item.category,
                useCount: 0,
                lastUsed: nil,
                createdAt: Date(),
                cholesterol: nil,
                saturatedFat: nil,
                // For sample items, the current values are the original values
                originalProtein: item.protein,
                originalFat: item.fat,
                originalTotalCarbs: item.carbs,
                originalFiber: item.fiber,
                originalSugarAlcohols: 0.0,
                originalNetCarbs: item.carbs - item.fiber,
                originalCalories: item.calories,
                originalServingSize: 1.0, // Sample items are already in their "base" serving size
                originalServingSizeUnit: "serving",
                originalCholesterol: nil,
                originalSaturatedFat: nil
            )
            quickAddItems.append(quickAddItem)
        }
        
        saveQuickAddItems()
        // Don't reload - @Published will update UI automatically
    }
}
