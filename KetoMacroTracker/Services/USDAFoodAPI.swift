import Foundation

// MARK: - USDA Food Data Models
struct USDAFood: Identifiable, Codable {
    let id: UUID
    let fdcId: Int
    let description: String
    let dataType: String?
    let foodNutrients: [USDAFoodNutrient]?
    let gtinUpc: String?
    let publishedDate: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodCategory: String?
    
    // Computed properties for easy access with data validation
    var protein: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1003 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var fat: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1004 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var totalCarbs: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1005 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var fiber: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1079 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var sugarAlcohols: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1017 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var calories: Double {
        let value = foodNutrients?.first { $0.nutrientId == 1008 }?.value ?? 0.0
        return max(0, value) // Ensure non-negative
    }
    
    var netCarbs: Double {
        max(0, totalCarbs - fiber - sugarAlcohols)
    }
    
    // Data quality check
    var hasValidNutritionData: Bool {
        return protein > 0 || fat > 0 || totalCarbs > 0 || calories > 0
    }
    
    // Format serving size with unit for display
    var formattedServingSize: String {
        if let size = servingSize, let unit = servingSizeUnit {
            if unit.lowercased() == "serving" || unit.lowercased() == "servings" {
                return "\(String(format: "%.1f", size)) serving\(size == 1 ? "" : "s")"
            } else {
                return "\(String(format: "%.1f", size))\(unit)"
            }
        } else if let size = servingSize {
            return "\(String(format: "%.1f", size))g"
        } else {
            return "100g" // Default
        }
    }
    
    // Format serving size for nutrition labels (e.g., "per 100g" or "per serving (50g)")
    var nutritionPerLabel: String {
        if let size = servingSize, let unit = servingSizeUnit {
            if unit.lowercased() == "serving" || unit.lowercased() == "servings" {
                return "per serving"
            } else {
                return "per \(String(format: "%.0f", size))\(unit)"
            }
        } else if let size = servingSize {
            return "per \(String(format: "%.0f", size))g"
        } else {
            return "per 100g"
        }
    }
}

struct USDAFoodNutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let nutrientNumber: String?
    let unitName: String?
    let value: Double?
    let rank: Int?
    let indentLevel: Int?
    let foodNutrientId: Int?
    let dataPoints: Int?
    let derivationCode: String?
    let derivationDescription: String?
    
    // Computed properties for backward compatibility
    var nutrient: USDANutrient? {
        guard let nutrientId = nutrientId else { return nil }
        return USDANutrient(
            id: nutrientId,
            name: nutrientName,
            unitName: unitName
        )
    }
    
    var amount: Double? {
        return value
    }
}

struct USDANutrient: Codable {
    let id: Int
    let name: String?
    let unitName: String?
}

struct USDASearchResponse: Codable {
    let foods: [USDAFood]?
    let totalHits: Int?
}

// MARK: - USDA Food API Service
class USDAFoodAPI: ObservableObject {
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiConfig = APIConfig.shared
    
    private var apiKey: String {
        apiConfig.usdaAPIKey
    }
    
    func searchFoods(query: String) async throws -> [USDAFood] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidQuery
        }
        
        let urlString = "\(baseURL)/foods/search?query=\(encodedQuery)&pageSize=20&api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        print("🌐 Making request to: \(urlString)")
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(from: url)
        let responseTime = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        // Handle rate limiting (429 Too Many Requests)
        if httpResponse.statusCode == 429 {
            let errorString = String(data: data, encoding: .utf8) ?? "Rate limit exceeded"
            print("⚠️ USDA API Rate Limit Reached (429): \(errorString)")
            print("📊 Rate limit monitoring: USDA API has reached 1000 requests/hour limit")
            
            // Track rate limit event
            APIUsageTracker.shared.trackUSDARequest(
                query: encodedQuery,
                success: false,
                errorType: "rateLimitExceeded",
                responseTime: responseTime
            )
            APIUsageTracker.shared.trackRateLimit()
            
            throw APIError.rateLimitExceeded
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error Response: \(errorString)")
            
            // Track failed request
            APIUsageTracker.shared.trackUSDARequest(
                query: encodedQuery,
                success: false,
                errorType: "http_\(httpResponse.statusCode)",
                responseTime: responseTime
            )
            
            throw APIError.invalidResponse
        }
        
        // Print raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw API Response: \(String(responseString.prefix(1000)))...")
        }
        
        do {
            // First decode the raw response to get the foods array
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let foodsArray = json?["foods"] as? [[String: Any]] ?? []
            
            var usdaFoods: [USDAFood] = []
            
            for foodDict in foodsArray {
                // Add a UUID for each food item
                var mutableFoodDict = foodDict
                mutableFoodDict["id"] = UUID().uuidString
                
                // Convert back to Data and decode
                let foodData = try JSONSerialization.data(withJSONObject: mutableFoodDict)
                let usdaFood = try JSONDecoder().decode(USDAFood.self, from: foodData)
                usdaFoods.append(usdaFood)
            }
            
            print("✅ Successfully parsed \(usdaFoods.count) foods")
            
            // Filter out foods with invalid nutrition data
            let validFoods = usdaFoods.filter { $0.hasValidNutritionData }
            print("✅ Filtered to \(validFoods.count) foods with valid nutrition data")
            
            // Debug first food's nutrition data
            if let firstFood = validFoods.first {
                print("🔍 First food: \(firstFood.description)")
                print("🔍 Nutrition count: \(firstFood.foodNutrients?.count ?? 0)")
                if let nutrients = firstFood.foodNutrients, !nutrients.isEmpty {
                    let firstNutrient = nutrients.first!
                    print("🔍 First nutrient: \(firstNutrient.nutrientName ?? "No name"), Value: \(firstNutrient.value ?? 0)")
                    print("🔍 Protein: \(firstFood.protein)g, Carbs: \(firstFood.totalCarbs)g, Fat: \(firstFood.fat)g")
                }
            }
            
            // Track successful request
            APIUsageTracker.shared.trackUSDARequest(
                query: encodedQuery,
                success: true,
                errorType: nil,
                responseTime: responseTime
            )
            
            return validFoods
        } catch {
            print("❌ JSON Decoding Error: \(error)")
            
            // Track failed request
            APIUsageTracker.shared.trackUSDARequest(
                query: encodedQuery,
                success: false,
                errorType: "decode_error",
                responseTime: responseTime
            )
            
            throw error
        }
    }
    
    func getFoodDetails(fdcId: Int) async throws -> USDAFood {
        let urlString = "\(baseURL)/food/\(fdcId)?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(USDAFood.self, from: data)
    }
}

enum APIError: Error {
    case invalidURL
    case invalidQuery
    case invalidResponse
    case noData
    case rateLimitExceeded
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidQuery:
            return "Invalid search query"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        }
    }
}
