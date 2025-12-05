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
    
    // Default values for new users
    static let defaultProfile = UserProfile(
        weight: 150.0,
        height: 170.0,
        age: 30,
        gender: "Male",
        activityLevel: "Moderately Active",
        goal: "Lose Fat"
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
            self.profile = savedProfile
            print("📱 Loaded saved profile: \(savedProfile)")
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
