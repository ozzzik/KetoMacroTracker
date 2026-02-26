//
//  ProfileManager.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/28/25.
//

import Foundation
import SwiftUI

// MARK: - User Profile Model
struct UserProfile: Codable, Equatable {
    var weight: Double // in lbs
    var height: Double // in cm
    var age: Int
    var gender: String // "Male" or "Female"
    var activityLevel: String
    var goal: String
    var cholesterolGoal: Double? // in mg, optional for backward compatibility
    var saturatedFatGoal: Double? // in g, optional for backward compatibility
    
    // Default values for new users
    static let defaultProfile = UserProfile(
        weight: 150.0,
        height: 170.0,
        age: 30,
        gender: "Male",
        activityLevel: "Moderately Active",
        goal: "Lose Fat",
        cholesterolGoal: 300.0, // Default: 300mg/day (recommended limit)
        saturatedFatGoal: 20.0 // Default: 20g/day (recommended limit)
    )
}

// MARK: - Profile Manager
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profile: UserProfile
    
    private let userDefaultsKey = "UserProfile"
    
    private init() {
        // Load profile from UserDefaults or use default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            var profile = savedProfile
            // Set default goals if not present (backward compatibility)
            if profile.cholesterolGoal == nil {
                profile.cholesterolGoal = 300.0 // Default: 300mg/day
            }
            if profile.saturatedFatGoal == nil {
                profile.saturatedFatGoal = 20.0 // Default: 20g/day
            }
            self.profile = profile
            print("📱 Loaded saved profile: \(profile)")
            // Save updated profile with defaults if needed
            if savedProfile.cholesterolGoal == nil || savedProfile.saturatedFatGoal == nil {
                saveProfile()
            }
        } else {
            self.profile = UserProfile.defaultProfile
            print("📱 Using default profile: \(profile)")
            saveProfile() // Save the default profile
        }
    }
    
    // MARK: - Public Methods
    func updateProfile(weight: Double, height: Double, age: Int, gender: String, activityLevel: String, goal: String) {
        print("🔄 ProfileManager: updateProfile() called")
        print("🔄 Old profile: \(profile)")
        
        profile.weight = weight
        profile.height = height
        profile.age = age
        profile.gender = gender
        profile.activityLevel = activityLevel
        profile.goal = goal
        
        print("🔄 New profile: \(profile)")
        saveProfile()
        print("📱 Profile updated and saved successfully")
    }
    
    func updateCholesterolGoal(_ goal: Double) {
        profile.cholesterolGoal = goal
        saveProfile()
        print("📱 Cholesterol goal updated to \(goal)mg")
    }
    
    func updateSaturatedFatGoal(_ goal: Double) {
        profile.saturatedFatGoal = goal
        saveProfile()
        print("📱 Saturated fat goal updated to \(goal)g")
    }
    
    func resetToDefaults() {
        profile = UserProfile.defaultProfile
        saveProfile()
        print("📱 Reset profile to defaults")
    }
    
    // MARK: - Private Methods
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved profile to UserDefaults")
        } else {
            print("❌ Failed to encode profile")
        }
    }
}
