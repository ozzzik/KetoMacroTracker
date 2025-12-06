import SwiftUI
import AVFoundation

struct FoodSearchView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var foodLogManager: FoodLogManager
    @ObservedObject var quickAddManager: QuickAddManager
    
    // Optional callback for custom meal creation (food, servings)
    var onFoodSelected: ((USDAFood, Double) -> Void)? = nil
    
    @State private var searchText = ""
    @State private var searchResults: [USDAFood] = []
    @State private var isLoading = false
    @State private var showingManualEntry = false
    @State private var showingQuickAddSuccess = false
    @State private var searchError: String?
    @State private var selectedBrand = "All Brands"
    @State private var availableBrands: [String] = []
    @State private var showingBarcodeScanner = false
    @State private var showingUnitSelection = false
    @State private var selectedFoodForUnitSelection: USDAFood?
    @State private var showingQuickAddCategory = false
    @State private var selectedFoodForQuickAdd: USDAFood?
    @State private var selectedFoodForManualEntry: USDAFood?
    @State private var showKetoFriendlyOnly = false
    @State private var sortOption: SortOption = .relevance
    @State private var showingBarcodeHistory = false
    
    @StateObject private var barcodeHistoryManager = BarcodeHistoryManager.shared
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case netCarbsLow = "Net Carbs (Low to High)"
        case netCarbsHigh = "Net Carbs (High to Low)"
        case caloriesLow = "Calories (Low to High)"
        case caloriesHigh = "Calories (High to Low)"
    }
    
    private let usdaAPI = USDAFoodAPI()
    private let openFoodFactsAPI = OpenFoodFactsAPI()
    private let settingsManager = AppSettingsManager.shared
    
    // MARK: - Computed Properties
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { searchFoods() }
                
                Button("Search") {
                    searchFoods()
                }
                .disabled(searchText.isEmpty || isLoading)
            }
            
            if isLoading {
                ProgressView("Searching...")
            }
        }
        .padding()
    }
    
    private var brandFilterSection: some View {
        Group {
            if !availableBrands.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["All Brands"] + availableBrands, id: \.self) { brand in
                            Button(brand) {
                                selectedBrand = brand
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedBrand == brand ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedBrand == brand ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var filterAndSortSection: some View {
        VStack(spacing: 12) {
            // Keto-friendly filter toggle
            HStack {
                Toggle("Keto-Friendly Only (≤20g net carbs)", isOn: $showKetoFriendlyOnly)
                    .font(AppTypography.caption)
            }
            .padding(.horizontal)
            
            // Sort options
            HStack {
                Text("Sort by:")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Picker("Sort", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(AppTypography.caption)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AppColors.secondaryBackground)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 20) {
            Button("Manual Entry") {
                print("🔄 FoodSearchView: Manual Entry button tapped")
                showingManualEntry = true
                print("🔄 showingManualEntry set to: \(showingManualEntry)")
            }
            .buttonStyle(.bordered)
            
            Button("Scan Barcode") {
                showingBarcodeScanner = true
            }
            .buttonStyle(.bordered)
            
            if !barcodeHistoryManager.history.isEmpty {
                Button(action: {
                    showingBarcodeHistory = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                searchBarSection
                
                // Filter and Sort Controls
                filterAndSortSection
                
                brandFilterSection
                actionButtonsSection
                
                // Status Display
                if let error = searchError {
                    VStack(alignment: .leading, spacing: 8) {
                        if error.contains("✅ Found product") {
                            Text(error)
                                .foregroundColor(.green)
                                .font(.caption)
                        } else if error.contains("Barcode scanned") {
                            Text("📱 \(error)")
                                .foregroundColor(.blue)
                                .font(.caption)
                        } else {
                            Text(error)
                                .foregroundColor(.red)
                        }
                        
                        if error.contains("Barcode scanned") {
                            Button("Try searching 'Kirkland Almond Beverage'") {
                                searchText = "Kirkland Almond Beverage"
                                searchError = nil
                                searchFoods()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Results
                List(filteredResults) { food in
                    FoodSearchResultRow(food: food, quickAddManager: quickAddManager, foodLogManager: foodLogManager) { food in
                        print("🔘 Add button pressed for: \(food.description)")
                        selectedFoodForUnitSelection = food
                        showingUnitSelection = true
                        print("📱 showingUnitSelection set to: \(showingUnitSelection)")
                    } onQuickAdd: { food in
                        print("🔘 Quick Add button pressed for: \(food.description)")
                        selectedFoodForQuickAdd = food
                        showingQuickAddCategory = true
                        print("📱 showingQuickAddCategory set to: \(showingQuickAddCategory)")
                    } onManualEntry: { food in
                        print("🔘 Manual Entry button pressed for: \(food.description)")
                        selectedFoodForManualEntry = food
                        showingManualEntry = true
                        print("📱 showingManualEntry set to: \(showingManualEntry)")
                    }
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: showingUnitSelection) { _, newValue in
                print("📱 showingUnitSelection changed to: \(newValue)")
            }
            .onChange(of: showingQuickAddCategory) { _, newValue in
                print("📱 showingQuickAddCategory changed to: \(newValue)")
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualFoodEntryView(foodLogManager: foodLogManager, quickAddManager: quickAddManager, sourceFood: selectedFoodForManualEntry) { food, servings in
                print("🔄 FoodSearchView: ManualFoodEntryView onSave callback called")
                print("🔄 Servings: \(servings)")
                // If callback is provided (for custom meals), use it with the servings
                if let callback = onFoodSelected {
                    callback(food, servings)
                    dismiss()
                } else {
                    addFoodToLog(food, servings: servings)
                }
                showingManualEntry = false
                selectedFoodForManualEntry = nil // Clear after use
            }
        }
        .onChange(of: showingManualEntry) { _, newValue in
            print("📱 showingManualEntry changed to: \(newValue)")
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(isPresented: $showingBarcodeScanner) { barcode in
                handleBarcodeScanned(barcode)
            }
        }
        .sheet(isPresented: $showingBarcodeHistory) {
            BarcodeHistoryView(
                barcodeHistoryManager: barcodeHistoryManager,
                onFoodSelected: { food in
                    if let callback = onFoodSelected {
                        callback(food, 1.0)
                        dismiss()
                    } else {
                        selectedFoodForUnitSelection = food
                        showingUnitSelection = true
                    }
                }
            )
        }
        .alert("Added to Quick Add!", isPresented: $showingQuickAddSuccess) {
            Button("OK") { }
        }
        .sheet(isPresented: $showingUnitSelection) {
            if let food = selectedFoodForUnitSelection {
                UnitSelectionView(food: food) { food, amount, unit in
                    print("🔄 FoodSearchView: UnitSelectionView callback called")
                    print("  - Food: \(food.description)")
                    print("  - Amount: \(amount) \(unit)")
                    
                    // Convert to servings first
                    let servings = convertToServings(amount: amount, unit: unit, food: food)
                    print("  - Converted to \(servings) servings")
                    
                    // If callback is provided (for custom meals), use it
                    if let callback = onFoodSelected {
                        print("  - Using onFoodSelected callback (custom meal)")
                        callback(food, servings)
                        dismiss()
                    } else {
                        print("  - Adding directly to food log")
                        addFoodToLog(food, amount: amount, unit: unit)
                    }
                }
            } else {
                Text("Error: No food selected")
            }
        }
        .sheet(isPresented: $showingQuickAddCategory) {
            if let food = selectedFoodForQuickAdd {
                QuickAddCategoryView(food: food, quickAddManager: quickAddManager)
            } else {
                Text("Error: No food selected")
            }
        }
    }
    
    private var filteredResults: [USDAFood] {
        var results = searchResults
        
        // Filter by brand
        if selectedBrand != "All Brands" {
            results = results.filter { $0.brandName == selectedBrand }
        }
        
        // Filter by keto-friendly (net carbs <= 20g)
        if showKetoFriendlyOnly {
            results = results.filter { $0.netCarbs <= 20.0 }
        }
        
        // Sort results
        switch sortOption {
        case .relevance:
            // Keep original order (relevance from API)
            break
        case .netCarbsLow:
            results = results.sorted { $0.netCarbs < $1.netCarbs }
        case .netCarbsHigh:
            results = results.sorted { $0.netCarbs > $1.netCarbs }
        case .caloriesLow:
            results = results.sorted { $0.calories < $1.calories }
        case .caloriesHigh:
            results = results.sorted { $0.calories > $1.calories }
        }
        
        return results
    }
    
    private func searchFoods() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        searchResults = []
        searchError = nil
        
        // Refresh country settings in case they changed
        openFoodFactsAPI.refreshCountriesFromSettings()
        
        Task {
            do {
                var usdaResults: [USDAFood] = []
                var offResults: [OpenFoodFactsProduct] = []
                
                // Search based on user preferences
                let searchUSDA = settingsManager.settings.searchUSDADatabase
                let searchOFF = settingsManager.settings.searchOpenFoodFacts
                
                if searchUSDA && searchOFF {
                    // Search both in parallel, with fallback if USDA fails
                    do {
                        async let usda = try usdaAPI.searchFoods(query: searchText)
                        async let off = try openFoodFactsAPI.searchProducts(query: searchText, pageSize: 10)
                        let (usdaData, offData) = try await (usda, off)
                        usdaResults = usdaData
                        offResults = offData
                    } catch APIError.rateLimitExceeded {
                        // USDA rate limit hit - fallback to OpenFoodFacts only
                        print("⚠️ USDA rate limit exceeded, falling back to OpenFoodFacts")
                        offResults = try await openFoodFactsAPI.searchProducts(query: searchText, pageSize: settingsManager.settings.maxSearchResults)
                    }
                } else if searchUSDA {
                    // USDA only - with fallback to OpenFoodFacts if rate limited
                    do {
                        usdaResults = try await usdaAPI.searchFoods(query: searchText)
                    } catch APIError.rateLimitExceeded {
                        // Silently fallback to OpenFoodFacts if enabled
                        if searchOFF {
                            print("⚠️ USDA rate limit exceeded, falling back to OpenFoodFacts")
                            offResults = try await openFoodFactsAPI.searchProducts(query: searchText, pageSize: settingsManager.settings.maxSearchResults)
                        } else {
                            // Re-throw if OpenFoodFacts is disabled
                            throw APIError.rateLimitExceeded
                        }
                    }
                } else if searchOFF {
                    // OpenFoodFacts only
                    offResults = try await openFoodFactsAPI.searchProducts(query: searchText, pageSize: settingsManager.settings.maxSearchResults)
                }
                
                // Convert OpenFoodFacts results to USDAFood format
                let offConverted = offResults.map { openFoodFactsAPI.convertToUSDAFood($0) }
                
                // Combine results: OpenFoodFacts first (local products), then USDA
                let combinedResults = offConverted + usdaResults
                
                await MainActor.run {
                    self.searchResults = Array(combinedResults.prefix(settingsManager.settings.maxSearchResults))
                    self.isLoading = false
                    
                    let brands = Set(combinedResults.compactMap { $0.brandName }.filter { !$0.isEmpty })
                    self.availableBrands = Array(brands).sorted()
                    self.selectedBrand = "All Brands"
                    
                    if combinedResults.isEmpty {
                        self.searchError = "No foods found for '\(searchText)'"
                    } else if settingsManager.settings.showDatabaseSource {
                        // Show which databases returned results
                        let countryName = settingsManager.getPreferredCountry().displayName
                        if !offConverted.isEmpty && !usdaResults.isEmpty {
                            self.searchError = "✅ Found \(offConverted.count) \(countryName) + \(usdaResults.count) USDA products"
                        } else if !offConverted.isEmpty {
                            self.searchError = "✅ Found \(offConverted.count) \(countryName) products"
                        } else if !usdaResults.isEmpty {
                            self.searchError = "✅ Found \(usdaResults.count) USDA products"
                        }
                    }
                }
            } catch APIError.rateLimitExceeded {
                // Handle rate limit - already handled in search logic above
                await MainActor.run {
                    // If we get here, both USDA and OpenFoodFacts failed or OpenFoodFacts is disabled
                    self.searchError = "Search temporarily unavailable. Please try again in a few minutes."
                    self.searchResults = []
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.searchError = "Failed to search foods: \(error.localizedDescription)"
                    self.searchResults = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addFoodToLog(_ food: USDAFood, servings: Double = 1.0) {
        print("🔄 FoodSearchView: addFoodToLog() called")
        print("🔄 Food: \(food.description)")
        print("🔄 Servings: \(servings)")
        print("🔄 Food protein: \(food.protein), carbs: \(food.totalCarbs), fat: \(food.fat)")
        
        // If callback is provided (for custom meals), use it instead
        if let callback = onFoodSelected {
            callback(food, servings)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
            return
        }
        
        // Add food on main thread (always use async to avoid deadlocks)
        Task { @MainActor in
            self.foodLogManager.addFood(food, servings: servings)
            // Small delay to ensure state updates complete before dismissing
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            self.dismiss()
        }
    }
    
    private func addFoodToLog(_ food: USDAFood, amount: Double, unit: String) {
        // Convert different units to servings based on the food's serving size
        let servings = convertToServings(amount: amount, unit: unit, food: food)
        
        // If callback is provided (for custom meals), use it instead
        if let callback = onFoodSelected {
            callback(food, servings)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
            return
        }
        
        // Add food on main thread (always use async to avoid deadlocks)
        Task { @MainActor in
            self.foodLogManager.addFood(food, servings: servings)
            // Small delay to ensure state updates complete before dismissing
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            self.dismiss()
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
        case "ml":
            amountInGrams = amount // Rough approximation for liquids
        case "l":
            amountInGrams = amount * 1000
        case "cups":
            amountInGrams = amount * 240 // Rough approximation
        case "tbsp":
            amountInGrams = amount * 15
        case "tsp":
            amountInGrams = amount * 5
        case "oz":
            amountInGrams = amount * 28.35
        case "lb":
            amountInGrams = amount * 453.6
        case "servings":
            return amount
        default:
            amountInGrams = amount
        }
        
        let servingSizeInGrams: Double
        switch servingUnit {
        case "g":
            servingSizeInGrams = servingSize
        case "ml":
            servingSizeInGrams = servingSize
        case "l":
            servingSizeInGrams = servingSize * 1000
        case "cups":
            servingSizeInGrams = servingSize * 240
        case "tbsp":
            servingSizeInGrams = servingSize * 15
        case "tsp":
            servingSizeInGrams = servingSize * 5
        case "oz":
            servingSizeInGrams = servingSize * 28.35
        case "lb":
            servingSizeInGrams = servingSize * 453.6
        default:
            servingSizeInGrams = servingSize
        }
        
        return amountInGrams / servingSizeInGrams
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        print("📱 Barcode scanned: \(barcode)")
        
        // Clear previous results and errors
        searchResults = []
        searchError = nil
        isLoading = true
        
        Task {
            do {
                // Try to lookup the product using OpenFoodFacts API
                if let product = try await openFoodFactsAPI.lookupProduct(barcode: barcode) {
                    // Convert OpenFoodFacts product to USDAFood format
                    let usdaFood = openFoodFactsAPI.convertToUSDAFood(product)
                    
                    await MainActor.run {
                        self.searchResults = [usdaFood]
                        self.isLoading = false
                        self.searchText = product.name
                        
                        // Add to barcode history
                        barcodeHistoryManager.addBarcode(barcode, food: usdaFood)
                        
                        // Show success message
                        self.searchError = "✅ Found product: \(product.name) (\(product.brand))"
                    }
                } else {
                    // Product not found in OpenFoodFacts
                    await MainActor.run {
                        self.isLoading = false
                        self.searchText = barcode
                        self.searchError = """
                        ❌ Product not found in database.
                        
                        Barcode: \(barcode)
                        
                        📝 Options:
                        1. Use "Manual Entry" to add it yourself
                        2. Search by product name instead
                        3. Help others: Add this product to openfoodfacts.org
                        """
                    }
                }
            } catch {
                // API error occurred
                await MainActor.run {
                    self.isLoading = false
                    self.searchText = barcode
                    self.searchError = "⚠️ Error looking up barcode: \(error.localizedDescription). Try searching manually for the product name."
                }
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Helper Views
struct FoodSearchResultRow: View {
    let food: USDAFood
    let quickAddManager: QuickAddManager
    let foodLogManager: FoodLogManager
    let onAdd: (USDAFood) -> Void
    let onQuickAdd: (USDAFood) -> Void
    let onManualEntry: (USDAFood) -> Void
    
    @State private var servingSize = "1.0"
    @State private var showingAddConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.description)
                    .font(.headline)
                    .lineLimit(2)
                
                if let category = food.foodCategory, !category.isEmpty && category != "Unknown" {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            if let brand = food.brandName, !brand.isEmpty {
                HStack {
                    Text("Brand:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
            }
            
            HStack {
                MacroInfo(title: "Protein", value: "\(String(format: "%.1f", food.protein))g", color: .red)
                MacroInfo(title: "Carbs", value: "\(String(format: "%.1f", food.netCarbs))g", color: .orange)
                MacroInfo(title: "Fat", value: "\(String(format: "%.1f", food.fat))g", color: .yellow)
                MacroInfo(title: "Cal", value: "\(String(format: "%.0f", food.calories))", color: .purple)
            }
            
            HStack {
                Text("Nutrition per 100g:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Net Carbs: \(String(format: "%.1f", food.netCarbs))g")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("How much you ate:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter amount", text: $servingSize)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .font(.caption)
                
                Text("× 100g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Tap Add to confirm")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
            
            HStack(spacing: 8) {
                Button("Add") {
                    print("🔘 Add button pressed for: \(food.description) with \(servingSize) servings")
                    showingAddConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("Quick Add") {
                    print("🔘 Quick Add button pressed for: \(food.description)")
                    onQuickAdd(food)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Manual") {
                    print("🔘 Manual Entry button pressed for: \(food.description)")
                    onManualEntry(food)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .alert("Add to Food Log", isPresented: $showingAddConfirmation) {
            TextField("Serving amount", text: $servingSize)
                .keyboardType(.decimalPad)
            
            Button("Add") {
                if let servings = Double(servingSize), servings > 0 {
                    // Directly add to food log with the serving size from text field
                    foodLogManager.addFood(food, servings: servings)
                    print("✅ Added \(servings) servings of \(food.description) to food log")
                } else {
                    // If invalid serving size, open unit selection
                    onAdd(food)
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add \(servingSize) servings of \(food.description) to your food log?")
        }
    }
}

struct MacroInfo: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationView {
        FoodSearchView(foodLogManager: FoodLogManager.shared, quickAddManager: QuickAddManager())
    }
}