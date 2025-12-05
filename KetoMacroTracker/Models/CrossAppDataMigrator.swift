//
//  CrossAppDataMigrator.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 1/11/25.
//

import Foundation

class CrossAppDataMigrator: ObservableObject {
    @Published var migrationStatus: MigrationStatus = .notStarted
    @Published var migrationProgress: Double = 0.0
    @Published var migrationMessage: String = ""
    
    enum MigrationStatus: Equatable {
        case notStarted
        case inProgress
        case completed
        case failed(String)
        case noDataFound
    }
    
    // Old app bundle identifier
    private let oldAppBundleID = "com.whio.KetoMacroTracker"
    
    // Data keys used by both apps
    private let dataKeys = [
        "UserProfile",
        "QuickAddItems", 
        "FoodLogData",
        "HistoricalData",
        "HistoricalFoodLogData",
        "AppSettings",
        "LastSavedDate",
        "AppDataVersion"
    ]
    
    func checkAndMigrateData() {
        migrationStatus = .inProgress
        migrationMessage = "Checking for existing data..."
        
        DispatchQueue.global(qos: .background).async {
            let hasExistingData = self.checkForExistingData()
            
            DispatchQueue.main.async {
                if hasExistingData {
                    self.migrationStatus = .completed
                    self.migrationMessage = "Found existing data! Your profile and food logs are ready to use."
                    self.migrationProgress = 1.0
                } else {
                    self.migrationStatus = .noDataFound
                    self.migrationMessage = "No existing data found. You can start fresh!"
                    self.migrationProgress = 1.0
                }
            }
        }
    }
    
    private func checkForExistingData() -> Bool {
        print("🔍 Checking for existing data in UserDefaults...")
        
        // Check current app's UserDefaults
        let currentAppData = checkCurrentAppData()
        if currentAppData {
            return true
        }
        
        // If no data in current app, try to access old app's data
        let oldAppData = checkOldAppData()
        if oldAppData {
            // If we found old app data, migrate it
            migrateOldAppData()
            return true
        }
        
        return false
    }
    
    private func checkCurrentAppData() -> Bool {
        print("🔍 Checking current app's UserDefaults...")
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        print("📋 Current app keys: \(Array(allKeys).sorted())")
        
        for key in dataKeys {
            if UserDefaults.standard.object(forKey: key) != nil {
                print("✅ Found data in current app for key: \(key)")
                return true
            }
        }
        return false
    }
    
    private func checkOldAppData() -> Bool {
        print("🔍 Checking for old app data...")
        
        // Try to access the old app's UserDefaults using the old bundle ID
        // This is tricky because UserDefaults is sandboxed by bundle ID
        // But we can try to read from the old app's container
        
        // Method 1: Try to access old app's UserDefaults directly
        if let oldAppDefaults = UserDefaults(suiteName: oldAppBundleID) {
            let oldKeys = oldAppDefaults.dictionaryRepresentation().keys
            print("📋 Old app keys: \(Array(oldKeys).sorted())")
            
            for key in dataKeys {
                if oldAppDefaults.object(forKey: key) != nil {
                    print("✅ Found data in old app for key: \(key)")
                    return true
                }
            }
        }
        
        // Method 2: Try to read from old app's container directory
        let oldAppContainerPath = getOldAppContainerPath()
        if let containerPath = oldAppContainerPath {
            print("🔍 Checking old app container: \(containerPath)")
            // This would require file system access which is complex
            // For now, we'll just log the path
        }
        
        return false
    }
    
    private func getOldAppContainerPath() -> String? {
        // This is a simplified approach - in reality, accessing another app's
        // container requires special entitlements or the app to be deleted
        let homeDirectory = NSHomeDirectory()
        let containerPath = "\(homeDirectory)/../\(oldAppBundleID)"
        return FileManager.default.fileExists(atPath: containerPath) ? containerPath : nil
    }
    
    private func migrateOldAppData() {
        print("🔄 Migrating data from old app...")
        // This would copy data from old app's UserDefaults to current app
        // Implementation would depend on what we find in checkOldAppData()
    }
    
    private func performMigration() {
        migrationMessage = "Starting data migration..."
        migrationProgress = 0.0
        
        var migratedItems = 0
        let totalItems = dataKeys.count
        
        for (index, key) in dataKeys.enumerated() {
            if UserDefaults.standard.data(forKey: key) != nil {
                // Data already exists in current app, so we keep it
                print("✅ Data for \(key) already exists in new app")
            } else {
                // Try to find and migrate data from old app
                if migrateDataForKey(key) {
                    migratedItems += 1
                    print("✅ Successfully migrated data for \(key)")
                } else {
                    print("ℹ️ No data found for \(key)")
                }
            }
            
            // Update progress
            let progress = Double(index + 1) / Double(totalItems)
            DispatchQueue.main.async {
                self.migrationProgress = progress
                self.migrationMessage = "Migrating data... \(Int(progress * 100))%"
            }
        }
        
        DispatchQueue.main.async {
            if migratedItems > 0 {
                self.migrationStatus = .completed
                self.migrationMessage = "Successfully migrated \(migratedItems) data items!"
            } else {
                self.migrationStatus = .noDataFound
                self.migrationMessage = "No new data to migrate"
            }
            self.migrationProgress = 1.0
        }
    }
    
    private func migrateDataForKey(_ key: String) -> Bool {
        // For this to work, we need to access the old app's UserDefaults
        // Since both apps are on the same device, we can use UserDefaults.standard
        // The key insight is that UserDefaults data persists even when bundle IDs change
        // if we're careful about how we access it
        
        // Check if data exists in the current UserDefaults (which might contain old data)
        if UserDefaults.standard.data(forKey: key) != nil {
            // Data exists, but we need to verify it's from the old app
            // For now, we'll assume any existing data is worth keeping
            return true
        }
        
        // Alternative approach: Check if we can access data through app group container
        // This would require both apps to be configured with the same app group
        return false
    }
    
    // MARK: - Manual Data Export/Import (Alternative Approach)
    
    func exportDataForMigration() -> String? {
        var exportData: [String: Data] = [:]
        
        for key in dataKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                exportData[key] = data
                print("📤 Exporting data for key: \(key)")
            }
        }
        
        // Convert to JSON and then to base64 string
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            let base64String = jsonData.base64EncodedString()
            print("📤 Export data ready: \(base64String.count) characters")
            return base64String
        } catch {
            print("❌ Failed to encode export data: \(error)")
            return nil
        }
    }
    
    func importMigratedData(_ importString: String) -> Bool {
        print("📥 Starting data import...")
        print("📥 Import string length: \(importString.count)")
        
        migrationStatus = .inProgress
        migrationMessage = "Importing migrated data..."
        migrationProgress = 0.0
        
        // Decode base64 string back to data
        guard let jsonData = Data(base64Encoded: importString) else {
            print("❌ Failed to decode base64 string")
            migrationStatus = .failed("Invalid base64 format")
            return false
        }
        
        print("📥 Decoded base64 to \(jsonData.count) bytes")
        
        guard let exportData = try? JSONDecoder().decode([String: Data].self, from: jsonData) else {
            print("❌ Failed to decode JSON data")
            migrationStatus = .failed("Invalid import data format")
            return false
        }
        
        print("📥 Decoded JSON with \(exportData.count) items")
        
        let totalItems = exportData.count
        var importedItems = 0
        
        for (index, (key, value)) in exportData.enumerated() {
            print("📥 Importing key: \(key) (\(value.count) bytes)")
            UserDefaults.standard.set(value, forKey: key)
            importedItems += 1
            
            let progress = Double(index + 1) / Double(totalItems)
            DispatchQueue.main.async {
                self.migrationProgress = progress
                self.migrationMessage = "Importing \(key)... \(Int(progress * 100))%"
            }
        }
        
        // Force synchronize to ensure data is written
        UserDefaults.standard.synchronize()
        print("📥 UserDefaults synchronized")
        
        // Verify the import
        print("📥 Verifying imported data...")
        for key in dataKeys {
            if UserDefaults.standard.object(forKey: key) != nil {
                print("✅ Verified: \(key) exists")
            } else {
                print("❌ Missing: \(key) not found")
            }
        }
        
        DispatchQueue.main.async {
            self.migrationStatus = .completed
            self.migrationMessage = "Successfully imported \(importedItems) data items! Please restart the app to see your data."
            self.migrationProgress = 1.0
        }
        
        print("✅ Import completed: \(importedItems) items")
        return true
    }
    
    // MARK: - Helper Methods
    
    func resetMigrationStatus() {
        migrationStatus = .notStarted
        migrationProgress = 0.0
        migrationMessage = ""
    }
    
    func getDataSummary() -> String {
        var summary = "Current App Data Summary:\n"
        for key in dataKeys {
            if UserDefaults.standard.object(forKey: key) != nil {
                summary += "✅ \(key)\n"
            } else {
                summary += "❌ \(key)\n"
            }
        }
        return summary
    }
}
