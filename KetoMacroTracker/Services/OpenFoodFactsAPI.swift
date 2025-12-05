import Foundation

// MARK: - OpenFoodFacts Data Models
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsSearchResponse: Codable {
    let count: Int?
    let page: Int?
    let pageSize: Int?
    let products: [OpenFoodFactsProduct]?
    
    enum CodingKeys: String, CodingKey {
        case count
        case page
        case pageSize = "page_size"
        case products
    }
}

// Alternative response structure for different API versions
struct OpenFoodFactsSearchResponseAlt: Codable {
    let status: Int?
    let count: Int?
    let page: Int?
    let products: [OpenFoodFactsProduct]?
}

struct OpenFoodFactsProduct: Codable, Identifiable {
    let id = UUID()
    let productName: String?
    let brands: String?
    let categories: String?
    let nutritionGrades: String?
    let nutriments: [String: OpenFoodFactsNutriment]?
    let imageUrl: String?
    let imageFrontUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case categories
        case nutritionGrades = "nutrition_grades"
        case nutriments
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
    }
    
    // Computed properties for easy access
    var name: String {
        return productName ?? "Unknown Product"
    }
    
    var brand: String {
        return brands ?? "Unknown Brand"
    }
    
    var category: String {
        return categories?.components(separatedBy: ",").first ?? "Unknown Category"
    }
    
    var protein: Double {
        return nutriments?["proteins_100g"]?.value ?? 
               nutriments?["protein_100g"]?.value ?? 0.0
    }
    
    var fat: Double {
        return nutriments?["fat_100g"]?.value ?? 
               nutriments?["total-fat_100g"]?.value ?? 
               nutriments?["lipids_100g"]?.value ?? 0.0
    }
    
    var totalCarbs: Double {
        return nutriments?["carbohydrates_100g"]?.value ?? 
               nutriments?["carbohydrate_100g"]?.value ?? 
               nutriments?["carbs_100g"]?.value ?? 0.0
    }
    
    var fiber: Double {
        return nutriments?["fiber_100g"]?.value ?? 
               nutriments?["fibers_100g"]?.value ?? 0.0
    }
    
    var sugarAlcohols: Double {
        return nutriments?["sugar-alcohols_100g"]?.value ?? 
               nutriments?["sugar-alcohol_100g"]?.value ?? 0.0
    }
    
    var sugars: Double {
        return nutriments?["sugars_100g"]?.value ?? 
               nutriments?["sugar_100g"]?.value ?? 0.0
    }
    
    var calories: Double {
        return nutriments?["energy-kcal_100g"]?.value ?? 
               nutriments?["energy_100g"]?.value ?? 
               nutriments?["calories_100g"]?.value ?? 0.0
    }
    
    var netCarbs: Double {
        // Net carbs = Total carbs - Fiber - Sugar alcohols
        // Note: Sugars are already included in total carbs, so we don't subtract them again
        return max(0, totalCarbs - fiber - sugarAlcohols)
    }
    
    // Check if product has valid nutrition data
    var hasValidNutritionData: Bool {
        return protein > 0 || fat > 0 || totalCarbs > 0 || calories > 0
    }
}

struct OpenFoodFactsNutriment: Codable {
    let value: Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as Double first
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        }
        // Try to decode as String and convert to Double
        else if let stringValue = try? container.decode(String.self),
                let doubleValue = Double(stringValue) {
            value = doubleValue
        }
        // Try to decode as Int and convert to Double
        else if let intValue = try? container.decode(Int.self) {
            value = Double(intValue)
        }
        else {
            value = nil
        }
    }
}

// MARK: - Country Configuration
enum OpenFoodFactsCountry: String, CaseIterable {
    case world = "world"
    
    // North America
    case usa = "us"
    case canada = "ca"
    case mexico = "mx"
    
    // South America
    case brazil = "br"
    case argentina = "ar"
    case chile = "cl"
    case colombia = "co"
    case peru = "pe"
    case venezuela = "ve"
    
    // Western Europe
    case uk = "uk"
    case france = "fr"
    case germany = "de"
    case spain = "es"
    case italy = "it"
    case netherlands = "nl"
    case belgium = "be"
    case switzerland = "ch"
    case austria = "at"
    case portugal = "pt"
    case ireland = "ie"
    case luxembourg = "lu"
    
    // Northern Europe
    case sweden = "se"
    case norway = "no"
    case denmark = "dk"
    case finland = "fi"
    case iceland = "is"
    
    // Eastern Europe
    case poland = "pl"
    case russia = "ru"
    case czechRepublic = "cz"
    case hungary = "hu"
    case romania = "ro"
    case ukraine = "ua"
    case greece = "gr"
    case turkey = "tr"
    
    // Middle East
    case israel = "il"
    case saudiArabia = "sa"
    case uae = "ae"
    case egypt = "eg"
    
    // Asia
    case japan = "jp"
    case china = "cn"
    case korea = "kr"
    case india = "in"
    case thailand = "th"
    case vietnam = "vn"
    case philippines = "ph"
    case indonesia = "id"
    case malaysia = "my"
    case singapore = "sg"
    case pakistan = "pk"
    case bangladesh = "bd"
    
    // Oceania
    case australia = "au"
    case newZealand = "nz"
    
    // Africa
    case southAfrica = "za"
    case nigeria = "ng"
    case kenya = "ke"
    case morocco = "ma"
    case algeria = "dz"
    
    var displayName: String {
        switch self {
        case .world: return "🌍 Global"
        
        // North America
        case .usa: return "🇺🇸 USA"
        case .canada: return "🇨🇦 Canada"
        case .mexico: return "🇲🇽 Mexico"
        
        // South America
        case .brazil: return "🇧🇷 Brazil"
        case .argentina: return "🇦🇷 Argentina"
        case .chile: return "🇨🇱 Chile"
        case .colombia: return "🇨🇴 Colombia"
        case .peru: return "🇵🇪 Peru"
        case .venezuela: return "🇻🇪 Venezuela"
        
        // Western Europe
        case .uk: return "🇬🇧 UK"
        case .france: return "🇫🇷 France"
        case .germany: return "🇩🇪 Germany"
        case .spain: return "🇪🇸 Spain"
        case .italy: return "🇮🇹 Italy"
        case .netherlands: return "🇳🇱 Netherlands"
        case .belgium: return "🇧🇪 Belgium"
        case .switzerland: return "🇨🇭 Switzerland"
        case .austria: return "🇦🇹 Austria"
        case .portugal: return "🇵🇹 Portugal"
        case .ireland: return "🇮🇪 Ireland"
        case .luxembourg: return "🇱🇺 Luxembourg"
        
        // Northern Europe
        case .sweden: return "🇸🇪 Sweden"
        case .norway: return "🇳🇴 Norway"
        case .denmark: return "🇩🇰 Denmark"
        case .finland: return "🇫🇮 Finland"
        case .iceland: return "🇮🇸 Iceland"
        
        // Eastern Europe
        case .poland: return "🇵🇱 Poland"
        case .russia: return "🇷🇺 Russia"
        case .czechRepublic: return "🇨🇿 Czech Republic"
        case .hungary: return "🇭🇺 Hungary"
        case .romania: return "🇷🇴 Romania"
        case .ukraine: return "🇺🇦 Ukraine"
        case .greece: return "🇬🇷 Greece"
        case .turkey: return "🇹🇷 Turkey"
        
        // Middle East
        case .israel: return "🇮🇱 Israel"
        case .saudiArabia: return "🇸🇦 Saudi Arabia"
        case .uae: return "🇦🇪 UAE"
        case .egypt: return "🇪🇬 Egypt"
        
        // Asia
        case .japan: return "🇯🇵 Japan"
        case .china: return "🇨🇳 China"
        case .korea: return "🇰🇷 South Korea"
        case .india: return "🇮🇳 India"
        case .thailand: return "🇹🇭 Thailand"
        case .vietnam: return "🇻🇳 Vietnam"
        case .philippines: return "🇵🇭 Philippines"
        case .indonesia: return "🇮🇩 Indonesia"
        case .malaysia: return "🇲🇾 Malaysia"
        case .singapore: return "🇸🇬 Singapore"
        case .pakistan: return "🇵🇰 Pakistan"
        case .bangladesh: return "🇧🇩 Bangladesh"
        
        // Oceania
        case .australia: return "🇦🇺 Australia"
        case .newZealand: return "🇳🇿 New Zealand"
        
        // Africa
        case .southAfrica: return "🇿🇦 South Africa"
        case .nigeria: return "🇳🇬 Nigeria"
        case .kenya: return "🇰🇪 Kenya"
        case .morocco: return "🇲🇦 Morocco"
        case .algeria: return "🇩🇿 Algeria"
        }
    }
    
    var baseURL: String {
        return "https://\(rawValue).openfoodfacts.org/api/v0"
    }
}

// MARK: - OpenFoodFacts API Service
class OpenFoodFactsAPI: ObservableObject {
    // Primary countries to search (in order of priority)
    private var primaryCountries: [OpenFoodFactsCountry]
    private let settingsManager = AppSettingsManager.shared
    
    init() {
        // Get countries from settings manager
        primaryCountries = settingsManager.getCountriesToSearch()
        print("🌍 Barcode databases configured: \(primaryCountries.map { $0.displayName }.joined(separator: ", "))")
    }
    
    // Update countries from settings
    func refreshCountriesFromSettings() {
        primaryCountries = settingsManager.getCountriesToSearch()
        print("🌍 Barcode databases updated: \(primaryCountries.map { $0.displayName }.joined(separator: ", "))")
    }
    
    
    // You can customize this based on user preference
    func setPreferredCountries(_ countries: [OpenFoodFactsCountry]) {
        primaryCountries = countries
        print("🌍 Barcode databases updated: \(primaryCountries.map { $0.displayName }.joined(separator: ", "))")
    }
    
    // Get current configured countries
    func getConfiguredCountries() -> [OpenFoodFactsCountry] {
        return primaryCountries
    }
    
    func lookupProduct(barcode: String) async throws -> OpenFoodFactsProduct? {
        // Try each country database in order until we find the product
        for country in primaryCountries {
            print("🔍 Searching \(country.displayName) database...")
            
            if let product = try await lookupInCountry(barcode: barcode, country: country) {
                print("✅ Found product in \(country.displayName) database!")
                return product
            }
        }
        
        // If not found in any configured country, return nil
        print("❌ Product not found in any configured database")
        return nil
    }
    
    private func lookupInCountry(barcode: String, country: OpenFoodFactsCountry) async throws -> OpenFoodFactsProduct? {
        let urlString = "\(country.baseURL)/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        print("🔍 OpenFoodFacts (\(country.displayName)): Looking up barcode \(barcode)")
        print("🌐 Making request to: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil // Try next country
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("❌ Not found in \(country.displayName) database (Status: \(httpResponse.statusCode))")
            return nil // Try next country
        }
        
        // Print raw response for debugging (first 2000 chars for barcode lookups)
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 ========== FULL API RESPONSE START ==========")
            print(String(responseString.prefix(2000)))
            if responseString.count > 2000 {
                print("... (truncated, total length: \(responseString.count) characters)")
            }
            print("📄 ========== FULL API RESPONSE END ==========")
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            print("✅ OpenFoodFacts: Status = \(apiResponse.status)")
            
            // Log the full product details if found
            if apiResponse.status == 1, let product = apiResponse.product {
                print("📦 ========== PRODUCT DETAILS START ==========")
                print("   Product Name: \(product.productName ?? "N/A")")
                print("   Brands: \(product.brands ?? "N/A")")
                print("   Categories: \(product.categories ?? "N/A")")
                print("   Nutrition Grade: \(product.nutritionGrades ?? "N/A")")
                print("   Image URL: \(product.imageUrl ?? "N/A")")
                print("   Nutrition per 100g:")
                print("     - Protein: \(product.protein)g")
                print("     - Carbs: \(product.totalCarbs)g")
                print("     - Fiber: \(product.fiber)g")
                print("     - Fat: \(product.fat)g")
                print("     - Calories: \(product.calories) kcal")
                print("     - Net Carbs: \(product.netCarbs)g")
                print("📦 ========== PRODUCT DETAILS END ==========")
            }
            print("✅ OpenFoodFacts: Status = \(apiResponse.status)")
            
            if apiResponse.status == 1, let product = apiResponse.product {
                print("✅ Found product: \(product.name)")
                print("🏷️ Brand: \(product.brand)")
                print("📊 Nutrition: \(product.protein)g protein, \(product.totalCarbs)g carbs, \(product.fat)g fat, \(product.calories) kcal")
                
                if product.hasValidNutritionData {
                    return product
                } else {
                    print("⚠️ Product found but no valid nutrition data")
                    return nil
                }
            } else {
                print("❌ No product found in \(country.displayName)")
                return nil
            }
        } catch {
            print("❌ Error decoding response from \(country.displayName): \(error)")
            return nil // Try next country
        }
    }
    
    // Search for products by text query
    func searchProducts(query: String, pageSize: Int = 20) async throws -> [OpenFoodFactsProduct] {
        var allResults: [OpenFoodFactsProduct] = []
        
        // Search in configured countries
        for country in primaryCountries {
            print("🔍 Searching \(country.displayName) database for '\(query)'...")
            
            if let products = try await searchInCountry(query: query, country: country, pageSize: pageSize) {
                print("✅ Found \(products.count) products in \(country.displayName)")
                allResults.append(contentsOf: products)
                
                // If we found enough results in the first database, stop searching
                if allResults.count >= pageSize {
                    break
                }
            }
        }
        
        // Remove duplicates based on product name and brand
        var seen = Set<String>()
        let uniqueProducts = allResults.filter { product in
            let key = "\(product.name)|\(product.brand)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
        
        return Array(uniqueProducts.prefix(pageSize))
    }
    
    private func searchInCountry(query: String, country: OpenFoodFactsCountry, pageSize: Int) async throws -> [OpenFoodFactsProduct]? {
        // Detect if query contains non-Latin characters (Hebrew, Arabic, Chinese, etc.)
        let containsUnicode = query.unicodeScalars.contains { scalar in
            // Hebrew: U+0590 to U+05FF
            // Arabic: U+0600 to U+06FF
            // Chinese: U+4E00 to U+9FFF
            // etc.
            return scalar.value > 127
        }
        
        if containsUnicode {
            print("🌐 Detected Unicode characters in search query: '\(query)'")
            print("   Language support: Hebrew (עברית), Arabic (العربية), Chinese (中文), etc.")
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        // Use the correct search endpoint - construct the base URL without the v0 suffix
        let baseWithoutVersion = "https://\(country.rawValue).openfoodfacts.org"
        let urlString = "\(baseWithoutVersion)/cgi/search.pl?search_terms=\(encodedQuery)&page_size=\(pageSize)&json=1"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        print("🌐 Making request to: \(urlString)")
        print("🔤 Original query: '\(query)'")
        print("🔤 Encoded query: '\(encodedQuery)'")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("❌ Search failed in \(country.displayName) (Status: \(httpResponse.statusCode))")
            return nil
        }
        
        // Print raw search response for debugging (first 2000 chars)
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 ========== SEARCH API RESPONSE START ==========")
            print(String(responseString.prefix(2000)))
            if responseString.count > 2000 {
                print("... (truncated, total length: \(responseString.count) characters)")
            }
            print("🔍 ========== SEARCH API RESPONSE END ==========")
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
            
            print("🔍 Search Response: Found \(searchResponse.count ?? 0) total results")
            
            // Filter products with valid nutrition data
            let validProducts = searchResponse.products?.filter { $0.hasValidNutritionData } ?? []
            
            print("✅ Found \(validProducts.count) valid products in \(country.displayName)")
            
            // Log first few products
            if !validProducts.isEmpty {
                print("📋 First few results:")
                for (index, product) in validProducts.prefix(3).enumerated() {
                    print("   \(index + 1). \(product.name) (\(product.brand))")
                }
            }
            
            return validProducts
        } catch {
            print("❌ Error decoding search response from \(country.displayName): \(error)")
            return nil
        }
    }
    
    func convertToUSDAFood(_ product: OpenFoodFactsProduct) -> USDAFood {
        // Create a USDAFood-like object from OpenFoodFacts data
        let nutrients: [USDAFoodNutrient] = [
            USDAFoodNutrient(
                nutrientId: 1003, // Protein
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "G",
                value: product.protein,
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
                value: product.fat,
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
                value: product.totalCarbs,
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
                value: product.fiber,
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
                value: product.calories,
                rank: 300,
                indentLevel: 1,
                foodNutrientId: nil,
                dataPoints: nil,
                derivationCode: nil,
                derivationDescription: nil
            )
        ]
        
        // Try to extract actual serving size from product name or use 100g as fallback
        let servingSize = extractServingSize(from: product.name) ?? 100.0
        
        print("🔍 OpenFoodFacts Debug - Product: \(product.name)")
        print("🔍 OpenFoodFacts Debug - Serving size: \(servingSize)g")
        
        // Debug: Show raw nutriments data
        if let nutriments = product.nutriments {
            print("🔍 Raw nutriments data:")
            for (key, value) in nutriments {
                if key.contains("100g") {
                    print("🔍   \(key): \(value.value ?? 0)")
                }
            }
        }
        
        print("🔍 OpenFoodFacts Debug - Protein: \(product.protein)g, Fat: \(product.fat)g, Carbs: \(product.totalCarbs)g")
        print("🔍 OpenFoodFacts Debug - Fiber: \(product.fiber)g, Sugars: \(product.sugars)g, Sugar Alcohols: \(product.sugarAlcohols)g")
        print("🔍 OpenFoodFacts Debug - Net Carbs: \(product.netCarbs)g, Calories: \(product.calories)kcal")
        
        return USDAFood(
            id: UUID(),
            fdcId: Int.random(in: 1000000...9999999), // Generate a fake FDC ID
            description: product.name,
            dataType: "OpenFoodFacts",
            foodNutrients: nutrients,
            gtinUpc: nil,
            publishedDate: nil,
            brandOwner: nil,
            brandName: product.brand,
            ingredients: nil,
            servingSize: servingSize, // Use detected serving size or 100g fallback
            servingSizeUnit: "g",
            foodCategory: product.category
        )
    }
    
    // MARK: - Helper Functions
    private func extractServingSize(from productName: String) -> Double? {
        let name = productName.lowercased()
        
        // Common patterns for serving sizes in product names
        let patterns = [
            // Tuna cans: "142g", "170g", "185g", "5oz", "6oz"
            "\\b(\\d+)\\s*g\\b",
            "\\b(\\d+)\\s*oz\\b",
            "\\b(\\d+)\\s*ml\\b",
            "\\b(\\d+)\\s*l\\b"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: name.utf16.count)
                if let match = regex.firstMatch(in: name, options: [], range: range) {
                    if let numberRange = Range(match.range(at: 1), in: name),
                       let number = Double(String(name[numberRange])) {
                        
                        // Convert to grams if needed
                        if pattern.contains("oz") {
                            return number * 28.35 // oz to grams
                        } else if pattern.contains("ml") {
                            return number // ml ≈ grams for most liquids
                        } else if pattern.contains("l") {
                            return number * 1000 // liters to grams
                        } else {
                            return number // already in grams
                        }
                    }
                }
            }
        }
        
        return nil
    }
}

enum OpenFoodFactsError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case productNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from OpenFoodFacts server"
        case .noData:
            return "No data received"
        case .productNotFound:
            return "Product not found in OpenFoodFacts database"
        }
    }
}
