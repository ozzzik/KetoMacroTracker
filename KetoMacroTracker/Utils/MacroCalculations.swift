//
//  MacroCalculations.swift
//  Keto Macro Tracker
//
//  Shared utility functions for macro calculations
//

import Foundation

// MARK: - Macro Calculations Utility
func calculateMacroGoals(profile: UserProfile) -> (protein: Double, carbs: Double, fat: Double, calories: Double) {
    // Convert weight from lbs to kg for BMR calculation
    let weightInKg = profile.weight * 0.453592 // 1 lb = 0.453592 kg
    
    // Calculate BMR using Mifflin-St Jeor Equation (metric)
    // Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) + 5
    // Women: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) - 161
    let bmr: Double
    if profile.gender == "Male" {
        bmr = (10 * weightInKg) + (6.25 * profile.height) - (5 * Double(profile.age)) + 5
    } else {
        bmr = (10 * weightInKg) + (6.25 * profile.height) - (5 * Double(profile.age)) - 161
    }
    
    // Activity multipliers
    let activityMultiplier: Double
    switch profile.activityLevel {
    case "Sedentary": activityMultiplier = 1.2
    case "Lightly Active": activityMultiplier = 1.375
    case "Moderately Active": activityMultiplier = 1.55
    case "Very Active": activityMultiplier = 1.725
    case "Extremely Active": activityMultiplier = 1.9
    default: activityMultiplier = 1.55
    }
    
    // Goal multipliers (scientifically-based for sustainable results)
    let goalMultiplier: Double
    switch profile.goal {
    case "Lose Fat": goalMultiplier = 0.80 // 20% deficit - sustainable fat loss
    case "Maintain Weight": goalMultiplier = 1.0 // No change
    case "Gain Weight": goalMultiplier = 1.15 // 15% surplus - lean mass gain
    default: goalMultiplier = 1.0
    }
    
    let tdee = bmr * activityMultiplier // Total Daily Energy Expenditure
    let calories = tdee * goalMultiplier
    
    // Macro calculations for keto (scientific approach)
    // Protein: Based on activity level and goal
    let baseProteinPerKg: Double
    switch profile.activityLevel {
    case "Sedentary": baseProteinPerKg = 1.5 // Middle of 1.4-1.6g/kg range
    case "Lightly Active": baseProteinPerKg = 1.7 // Middle of 1.6-1.8g/kg range
    case "Moderately Active": baseProteinPerKg = 1.9 // Middle of 1.8-2.0g/kg range
    case "Very Active": baseProteinPerKg = 2.1 // Middle of 2.0-2.2g/kg range
    case "Extremely Active": baseProteinPerKg = 2.3 // Middle of 2.2-2.4g/kg range
    default: baseProteinPerKg = 1.9
    }
    
    // Adjust protein based on goal
    let proteinPerKg: Double
    switch profile.goal {
    case "Lose Fat":
        proteinPerKg = baseProteinPerKg + 0.2 // Higher protein for fat loss to preserve muscle
    case "Maintain Weight":
        proteinPerKg = baseProteinPerKg // Standard protein for maintenance
    case "Gain Weight":
        proteinPerKg = baseProteinPerKg + 0.1 // Slightly higher for muscle gain
    default:
        proteinPerKg = baseProteinPerKg
    }
    
    let protein = weightInKg * proteinPerKg
    let carbs = 30.0 // Fixed keto carb limit (30g as specified)
    
    // Calculate macros according to keto scientific approach
    let proteinCalories = protein * 4
    let carbCalories = carbs * 4
    let fatCalories = calories - proteinCalories - carbCalories
    let fat = max(0, fatCalories / 9) // Fat grams = fat calories ÷ 9
    
    return (protein: protein, carbs: carbs, fat: fat, calories: calories)
}

