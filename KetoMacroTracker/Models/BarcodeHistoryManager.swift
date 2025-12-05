//
//  BarcodeHistoryManager.swift
//  Keto Macro Tracker
//
//  Manages history of scanned barcodes
//

import Foundation

struct BarcodeHistoryItem: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let foodName: String
    let dateScanned: Date
    let food: USDAFood
    
    init(barcode: String, food: USDAFood) {
        self.id = UUID()
        self.barcode = barcode
        self.foodName = food.description
        self.dateScanned = Date()
        self.food = food
    }
}

class BarcodeHistoryManager: ObservableObject {
    static let shared = BarcodeHistoryManager()
    
    @Published var history: [BarcodeHistoryItem] = []
    
    private let userDefaultsKey = "BarcodeHistory"
    private let maxHistoryItems = 50
    
    private init() {
        loadHistory()
    }
    
    func addBarcode(_ barcode: String, food: USDAFood) {
        // Remove existing entry with same barcode
        history.removeAll { $0.barcode == barcode }
        
        // Add new entry at the beginning
        let item = BarcodeHistoryItem(barcode: barcode, food: food)
        history.insert(item, at: 0)
        
        // Keep only recent items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        saveHistory()
        print("📱 Added barcode to history: \(barcode) - \(food.description)")
    }
    
    func getRecentBarcodes(limit: Int = 10) -> [BarcodeHistoryItem] {
        return Array(history.prefix(limit))
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([BarcodeHistoryItem].self, from: data) else {
            return
        }
        history = decoded
        print("📱 Loaded \(history.count) barcode history items")
    }
}

