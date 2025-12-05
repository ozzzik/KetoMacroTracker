//
//  LeftoverManager.swift
//  Keto Macro Tracker
//
//  Manages leftover meals that can be finished later
//

import Foundation

struct Leftover: Identifiable, Codable {
    let id: UUID
    let name: String
    let foods: [CustomMealFood]
    let totalNutrition: MacroNutrition
    let dateCreated: Date
    let expirationDate: Date // Typically 3-4 days from creation
    
    var isExpired: Bool {
        Date() > expirationDate
    }
    
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, days)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        foods: [CustomMealFood],
        totalNutrition: MacroNutrition,
        dateCreated: Date = Date(),
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.foods = foods
        self.totalNutrition = totalNutrition
        self.dateCreated = dateCreated
        self.expirationDate = expirationDate ?? Calendar.current.date(byAdding: .day, value: 4, to: dateCreated) ?? dateCreated
    }
}

class LeftoverManager: ObservableObject {
    static let shared = LeftoverManager()
    
    @Published var leftovers: [Leftover] = []
    
    private let userDefaultsKey = "Leftovers"
    
    private init() {
        loadLeftovers()
        cleanupExpired()
    }
    
    func addLeftover(name: String, foods: [CustomMealFood], totalNutrition: MacroNutrition) {
        let leftover = Leftover(
            name: name,
            foods: foods,
            totalNutrition: totalNutrition
        )
        leftovers.append(leftover)
        saveLeftovers()
        print("🍱 Added leftover: \(name)")
    }
    
    func finishLeftover(_ leftover: Leftover, servings: Double = 1.0, to foodLogManager: FoodLogManager) {
        // Add each food from the leftover to today's log
        for customFood in leftover.foods {
            let adjustedServings = customFood.servings * servings
            foodLogManager.addFood(customFood.food, servings: adjustedServings)
        }
        
        // Remove the leftover
        removeLeftover(leftover)
        print("✅ Finished leftover: \(leftover.name)")
    }
    
    func removeLeftover(_ leftover: Leftover) {
        leftovers.removeAll { $0.id == leftover.id }
        saveLeftovers()
    }
    
    func cleanupExpired() {
        let beforeCount = leftovers.count
        leftovers = leftovers.filter { !$0.isExpired }
        let afterCount = leftovers.count
        
        if beforeCount != afterCount {
            saveLeftovers()
            print("🧹 Cleaned up \(beforeCount - afterCount) expired leftovers")
        }
    }
    
    private func saveLeftovers() {
        if let encoded = try? JSONEncoder().encode(leftovers) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLeftovers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Leftover].self, from: data) else {
            return
        }
        leftovers = decoded
        print("🍱 Loaded \(leftovers.count) leftovers")
    }
}

