#!/usr/bin/env python3
"""
KetoMacroTracker - Macro Calculation Verification Script

This script verifies the macro calculations used in the iOS app.
Run with: python3 verify_calculations.py
"""

def calculate_macros(weight_lbs, height_cm, age, gender, activity_level, goal):
    """
    Calculate macro targets using the same logic as the iOS app
    
    Args:
        weight_lbs: Weight in pounds
        height_cm: Height in centimeters  
        age: Age in years
        gender: "Male" or "Female"
        activity_level: "Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"
        goal: "Lose Fat", "Maintain Weight", "Gain Weight"
    
    Returns:
        dict: Macro targets in grams and calories
    """
    
    # Step 1: Weight conversion
    weight_kg = weight_lbs * 0.453592
    
    # Step 2: BMR calculation (Mifflin-St Jeor Equation)
    if gender == "Male":
        bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
    else:
        bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
    
    # Step 3: Activity multipliers
    activity_multipliers = {
        "Sedentary": 1.2,
        "Lightly Active": 1.375,
        "Moderately Active": 1.55,
        "Very Active": 1.725,
        "Extremely Active": 1.9
    }
    
    # Step 4: Goal multipliers
    goal_multipliers = {
        "Lose Fat": 0.80,
        "Maintain Weight": 1.0,
        "Gain Weight": 1.15
    }
    
    # Calculate TDEE and calorie goal
    tdee = bmr * activity_multipliers[activity_level]
    calorie_goal = tdee * goal_multipliers[goal]
    
    # Step 5: Base protein per kg (by activity level)
    base_protein_per_kg = {
        "Sedentary": 1.5,
        "Lightly Active": 1.7,
        "Moderately Active": 1.9,
        "Very Active": 2.1,
        "Extremely Active": 2.3
    }
    
    # Step 6: Goal adjustments
    goal_adjustments = {
        "Lose Fat": 0.2,
        "Maintain Weight": 0.0,
        "Gain Weight": 0.1
    }
    
    # Calculate protein
    adjusted_protein_per_kg = base_protein_per_kg[activity_level] + goal_adjustments[goal]
    protein_grams = weight_kg * adjusted_protein_per_kg
    
    # Step 7: Fixed carb limit
    carb_grams = 30.0
    
    # Step 8: Calculate fat
    protein_calories = protein_grams * 4
    carb_calories = carb_grams * 4
    fat_calories = calorie_goal - protein_calories - carb_calories
    fat_grams = max(0, fat_calories / 9)
    
    return {
        "weight_kg": round(weight_kg, 2),
        "bmr": round(bmr, 1),
        "tdee": round(tdee, 1),
        "calorie_goal": round(calorie_goal, 1),
        "protein_grams": round(protein_grams, 1),
        "protein_calories": round(protein_calories, 1),
        "carb_grams": carb_grams,
        "carb_calories": carb_calories,
        "fat_grams": round(fat_grams, 1),
        "fat_calories": round(fat_calories, 1),
        "total_calories": round(protein_calories + carb_calories + fat_calories, 1)
    }

def print_results(profile, results):
    """Print formatted results"""
    print(f"\n{'='*60}")
    print(f"PROFILE: {profile}")
    print(f"{'='*60}")
    
    print(f"Weight: {results['weight_kg']} kg")
    print(f"BMR: {results['bmr']} calories/day")
    print(f"TDEE: {results['tdee']} calories/day")
    print(f"Calorie Goal: {results['calorie_goal']} calories/day")
    
    print(f"\nMACRO TARGETS:")
    print(f"Protein: {results['protein_grams']}g ({results['protein_calories']} calories)")
    print(f"Net Carbs: {results['carb_grams']}g ({results['carb_calories']} calories)")
    print(f"Fat: {results['fat_grams']}g ({results['fat_calories']} calories)")
    print(f"Total: {results['total_calories']} calories")
    
    # Calculate percentages
    protein_pct = (results['protein_calories'] / results['total_calories']) * 100
    carb_pct = (results['carb_calories'] / results['total_calories']) * 100
    fat_pct = (results['fat_calories'] / results['total_calories']) * 100
    
    print(f"\nMACRO PERCENTAGES:")
    print(f"Protein: {protein_pct:.1f}%")
    print(f"Net Carbs: {carb_pct:.1f}%")
    print(f"Fat: {fat_pct:.1f}%")

def main():
    """Main function with test cases"""
    
    print("KetoMacroTracker - Macro Calculation Verification")
    print("=" * 60)
    
    # Test case 1: Default profile from app
    test_cases = [
        {
            "name": "Default Profile (Male, 150 lbs, 170 cm, 30 years, Moderately Active, Lose Fat)",
            "weight_lbs": 150,
            "height_cm": 170,
            "age": 30,
            "gender": "Male",
            "activity_level": "Moderately Active",
            "goal": "Lose Fat"
        },
        {
            "name": "Female Profile (140 lbs, 165 cm, 25 years, Lightly Active, Maintain Weight)",
            "weight_lbs": 140,
            "height_cm": 165,
            "age": 25,
            "gender": "Female",
            "activity_level": "Lightly Active",
            "goal": "Maintain Weight"
        },
        {
            "name": "High Activity Profile (180 lbs, 185 cm, 35 years, Very Active, Gain Weight)",
            "weight_lbs": 180,
            "height_cm": 185,
            "age": 35,
            "gender": "Male",
            "activity_level": "Very Active",
            "goal": "Gain Weight"
        }
    ]
    
    for test_case in test_cases:
        results = calculate_macros(**{k: v for k, v in test_case.items() if k != "name"})
        print_results(test_case["name"], results)
    
    print(f"\n{'='*60}")
    print("VERIFICATION COMPLETE")
    print("Compare these results with the iOS app console logs")
    print("Expected format: Protein: X.Xg, Carbs: 30g, Fat: X.Xg, Calories: XXXX")

if __name__ == "__main__":
    main()
