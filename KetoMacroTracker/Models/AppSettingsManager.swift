//
//  AppSettingsManager.swift
//  Keto Macro Tracker
//
//  Manages app-wide settings for food search and barcode scanning
//

import Foundation
import SwiftUI

// MARK: - App Settings Model
struct AppSettings: Codable, Equatable {
    var searchUSDADatabase: Bool
    var searchOpenFoodFacts: Bool
    var maxSearchResults: Int
    var showDatabaseSource: Bool
    var preferredCountry: String // Raw value of OpenFoodFactsCountry
    var additionalCountries: [String] // Additional countries to search
    
    // Default values for new users
    static let defaultSettings = AppSettings(
        searchUSDADatabase: true,
        searchOpenFoodFacts: true,
        maxSearchResults: 20,
        showDatabaseSource: true,
        preferredCountry: "us", // USA as default
        additionalCountries: [] // Can be expanded to include more countries
    )
}

// MARK: - App Settings Manager
class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()
    
    @Published var settings: AppSettings
    
    private let userDefaultsKey = "AppSettings"
    
    private init() {
        // Load settings from UserDefaults or use default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = savedSettings
            print("⚙️ Loaded saved settings: \(savedSettings)")
        } else {
            self.settings = AppSettings.defaultSettings
            print("⚙️ Using default settings: \(settings)")
            saveSettings() // Save the default settings
        }
    }
    
    // MARK: - Public Methods
    
    /// Get the user's preferred country for OpenFoodFacts searches
    func getPreferredCountry() -> OpenFoodFactsCountry {
        return OpenFoodFactsCountry(rawValue: settings.preferredCountry) ?? .usa
    }
    
    /// Get the list of countries to search (in order of priority)
    func getCountriesToSearch() -> [OpenFoodFactsCountry] {
        var countries: [OpenFoodFactsCountry] = []
        
        // Add preferred country first
        countries.append(getPreferredCountry())
        
        // Add additional countries
        for countryRaw in settings.additionalCountries {
            if let country = OpenFoodFactsCountry(rawValue: countryRaw),
               !countries.contains(country) {
                countries.append(country)
            }
        }
        
        // If no countries configured, fall back to USA
        if countries.isEmpty {
            countries.append(.usa)
        }
        
        return countries
    }
    
    /// Update search database preferences
    func updateSearchPreferences(searchUSDA: Bool, searchOFF: Bool) {
        settings.searchUSDADatabase = searchUSDA
        settings.searchOpenFoodFacts = searchOFF
        saveSettings()
        print("⚙️ Updated search preferences: USDA=\(searchUSDA), OFF=\(searchOFF)")
    }
    
    /// Update preferred country for barcode scanning
    func updatePreferredCountry(_ country: OpenFoodFactsCountry) {
        settings.preferredCountry = country.rawValue
        saveSettings()
        print("⚙️ Updated preferred country to: \(country.displayName)")
    }
    
    /// Add additional country to search
    func addCountry(_ country: OpenFoodFactsCountry) {
        if !settings.additionalCountries.contains(country.rawValue) &&
           country.rawValue != settings.preferredCountry {
            settings.additionalCountries.append(country.rawValue)
            saveSettings()
            print("⚙️ Added country: \(country.displayName)")
        }
    }
    
    /// Remove country from additional search list
    func removeCountry(_ country: OpenFoodFactsCountry) {
        settings.additionalCountries.removeAll { $0 == country.rawValue }
        saveSettings()
        print("⚙️ Removed country: \(country.displayName)")
    }
    
    /// Update max search results
    func updateMaxSearchResults(_ max: Int) {
        settings.maxSearchResults = max
        saveSettings()
        print("⚙️ Updated max search results to: \(max)")
    }
    
    /// Toggle showing database source in results
    func toggleShowDatabaseSource() {
        settings.showDatabaseSource.toggle()
        saveSettings()
        print("⚙️ Show database source: \(settings.showDatabaseSource)")
    }
    
    /// Reset to default settings
    func resetToDefaults() {
        settings = AppSettings.defaultSettings
        saveSettings()
        print("⚙️ Reset settings to defaults")
    }
    
    // MARK: - Private Methods
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved settings to UserDefaults")
        } else {
            print("❌ Failed to encode settings")
        }
    }
}



