//
//  DataMigrationManager.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/29/25.
//

import Foundation

// MARK: - Data Migration Manager
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private let appVersionKey = "AppDataVersion"
    private let currentDataVersion = "1.0.0"
    
    private init() {
        migrateDataIfNeeded()
    }
    
    // MARK: - Migration Logic
    private func migrateDataIfNeeded() {
        let savedVersion = UserDefaults.standard.string(forKey: appVersionKey) ?? "0.0.0"
        
        if savedVersion != currentDataVersion {
            print("🔄 Starting data migration from version \(savedVersion) to \(currentDataVersion)")
            
            // Perform migrations based on version
            migrateFromVersion(savedVersion, to: currentDataVersion)
            
            // Update the saved version
            UserDefaults.standard.set(currentDataVersion, forKey: appVersionKey)
            
            print("✅ Data migration completed successfully")
        } else {
            print("✅ Data is up to date (version \(currentDataVersion))")
        }
    }
    
    private func migrateFromVersion(_ fromVersion: String, to toVersion: String) {
        // Handle migrations based on version changes
        
        // Migration 1.0.0: Ensure all data structures are compatible
        if fromVersion < "1.0.0" {
            migrateToVersion1_0_0()
        }
        
        // Future migrations can be added here
        // if fromVersion < "1.1.0" { migrateToVersion1_1_0() }
        // if fromVersion < "2.0.0" { migrateToVersion2_0_0() }
    }
    
    // MARK: - Specific Migrations
    private func migrateToVersion1_0_0() {
        print("🔄 Migrating to version 1.0.0")
        
        // Ensure UserProfile has default values
        migrateUserProfile()
        
        // Ensure QuickAddItem has backward compatibility fields
        migrateQuickAddItems()
        
        // Ensure LoggedFood structure is compatible
        migrateFoodLogData()
        
        // Ensure HistoricalData structure is compatible
        migrateHistoricalData()
    }
    
        private func migrateUserProfile() {
            let profileKey = "UserProfile"
            
            // If profile exists but might be missing fields, re-save it
            if UserDefaults.standard.data(forKey: profileKey) != nil {
                if let data = UserDefaults.standard.data(forKey: profileKey) {
                    do {
                        let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                        // Re-encode to ensure all fields are present with defaults
                        let encodedData = try JSONEncoder().encode(profile)
                        UserDefaults.standard.set(encodedData, forKey: profileKey)
                        print("✅ UserProfile migrated successfully")
                    } catch {
                        print("⚠️ Failed to migrate UserProfile: \(error)")
                        // If decoding fails due to missing gender field, create a new profile with defaults
                        let defaultProfile = UserProfile.defaultProfile
                        if let encodedData = try? JSONEncoder().encode(defaultProfile) {
                            UserDefaults.standard.set(encodedData, forKey: profileKey)
                            print("✅ Created new UserProfile with default values")
                        }
                    }
                }
            }
        }
    
    private func migrateQuickAddItems() {
        let quickAddKey = "QuickAddItems"
        
        if let data = UserDefaults.standard.data(forKey: quickAddKey) {
            do {
                let items = try JSONDecoder().decode([QuickAddItem].self, from: data)
                // Re-encode to ensure all new fields have default values
                let encodedData = try JSONEncoder().encode(items)
                UserDefaults.standard.set(encodedData, forKey: quickAddKey)
                print("✅ QuickAddItems migrated successfully")
            } catch {
                print("⚠️ Failed to migrate QuickAddItems: \(error)")
            }
        }
    }
    
    private func migrateFoodLogData() {
        let foodLogKey = "FoodLogData"
        
        if let data = UserDefaults.standard.data(forKey: foodLogKey) {
            do {
                let foods = try JSONDecoder().decode([LoggedFood].self, from: data)
                // Re-encode to ensure all fields are present
                let encodedData = try JSONEncoder().encode(foods)
                UserDefaults.standard.set(encodedData, forKey: foodLogKey)
                print("✅ FoodLogData migrated successfully")
            } catch {
                print("⚠️ Failed to migrate FoodLogData: \(error)")
            }
        }
    }
    
    private func migrateHistoricalData() {
        let historicalKey = "HistoricalFoodLogData"
        
        if let data = UserDefaults.standard.data(forKey: historicalKey) {
            do {
                let summaries = try JSONDecoder().decode([DailySummary].self, from: data)
                // Re-encode to ensure all fields are present
                let encodedData = try JSONEncoder().encode(summaries)
                UserDefaults.standard.set(encodedData, forKey: historicalKey)
                print("✅ HistoricalData migrated successfully")
            } catch {
                print("⚠️ Failed to migrate HistoricalData: \(error)")
            }
        }
    }
    
    // MARK: - Data Integrity Checks
    func verifyDataIntegrity() -> Bool {
        var allDataValid = true
        
        // Check UserProfile
        if let profileData = UserDefaults.standard.data(forKey: "UserProfile") {
            do {
                _ = try JSONDecoder().decode(UserProfile.self, from: profileData)
            } catch {
                print("⚠️ UserProfile data corruption detected: \(error)")
                allDataValid = false
            }
        }
        
        // Check QuickAddItems
        if let quickAddData = UserDefaults.standard.data(forKey: "QuickAddItems") {
            do {
                _ = try JSONDecoder().decode([QuickAddItem].self, from: quickAddData)
            } catch {
                print("⚠️ QuickAddItems data corruption detected: \(error)")
                allDataValid = false
            }
        }
        
        // Check FoodLogData
        if let foodLogData = UserDefaults.standard.data(forKey: "FoodLogData") {
            do {
                _ = try JSONDecoder().decode([LoggedFood].self, from: foodLogData)
            } catch {
                print("⚠️ FoodLogData data corruption detected: \(error)")
                allDataValid = false
            }
        }
        
        // Check HistoricalData
        if let historicalData = UserDefaults.standard.data(forKey: "HistoricalFoodLogData") {
            do {
                _ = try JSONDecoder().decode([DailySummary].self, from: historicalData)
            } catch {
                print("⚠️ HistoricalData data corruption detected: \(error)")
                allDataValid = false
            }
        }
        
        if allDataValid {
            print("✅ All data integrity checks passed")
        }
        
        return allDataValid
    }
    
    // MARK: - Backup and Restore
    func createDataBackup() -> [String: Data] {
        var backup: [String: Data] = [:]
        
        let keys = [
            "UserProfile",
            "QuickAddItems", 
            "FoodLogData",
            "HistoricalFoodLogData",
            "LastAccessedDate",
            "AppDataVersion"
        ]
        
        for key in keys {
            if let data = UserDefaults.standard.data(forKey: key) {
                backup[key] = data
            }
        }
        
        print("💾 Created backup with \(backup.count) data keys")
        return backup
    }
    
    func restoreDataBackup(_ backup: [String: Data]) -> Bool {
        for (key, data) in backup {
            UserDefaults.standard.set(data, forKey: key)
        }
        
        // Verify restored data
        if verifyDataIntegrity() {
            print("✅ Data backup restored successfully")
            return true
        } else {
            print("❌ Restored data failed integrity check")
            return false
        }
    }
}

// MARK: - JSONDecoder Extension for Safe Decoding
extension JSONDecoder {
    func safeDecode<T: Codable>(_ type: T.Type, from data: Data) -> T? {
        do {
            return try self.decode(type, from: data)
        } catch {
            print("❌ JSON Decode error for \(type): \(error)")
            return nil
        }
    }
}
