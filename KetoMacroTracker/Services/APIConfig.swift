//
//  APIConfig.swift
//  Keto Macro Tracker
//
//  API Configuration Manager - Loads API keys from secure config file
//

import Foundation

class APIConfig {
    static let shared = APIConfig()
    
    private let configFileName = "APIKeys"
    private let configFileExtension = "plist"
    
    private var config: [String: String] = [:]
    
    private init() {
        loadConfig()
    }
    
    // MARK: - Public API
    
    var usdaAPIKey: String {
        // First try to load from config file
        if let key = config["USDA_API_KEY"], !key.isEmpty {
            return key
        }
        
        // Fallback to hardcoded key (for development/backward compatibility)
        // This should be removed in production
        return "kipaOMjCe0LZgJubKNe4aEdYnApEy07Ebi7onTNn"
    }
    
    // MARK: - Private Methods
    
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: configFileExtension) else {
            print("⚠️ APIConfig: APIKeys.plist not found. Using fallback key.")
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ APIConfig: Could not read APIKeys.plist. Using fallback key.")
            return
        }
        
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            print("⚠️ APIConfig: Invalid format in APIKeys.plist. Using fallback key.")
            return
        }
        
        config = plist
        print("✅ APIConfig: Successfully loaded API keys from config file.")
    }
}

