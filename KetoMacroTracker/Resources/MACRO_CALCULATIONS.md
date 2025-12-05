# KetoMacroTracker - Macro Calculation Documentation

## Overview
This document details all macro calculations performed in the KetoMacroTracker app. All calculations are now standardized across DashboardTodayView, ProfileView, and EditProfileView.

## 1. BMR (Basal Metabolic Rate) Calculation

### Formula: Mifflin-St Jeor Equation (Metric)
**For Men:**
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age_years) + 5
```

**For Women:**
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age_years) - 161
```

### Input Conversion
```
weight_kg = weight_lbs × 0.453592
```

### Example Calculation (Male, 30 years old, 150 lbs, 170 cm)
```
weight_kg = 150 × 0.453592 = 68.04 kg
BMR = (10 × 68.04) + (6.25 × 170) - (5 × 30) + 5
BMR = 680.4 + 1062.5 - 150 + 5
BMR = 1597.9 calories/day
```

## 2. TDEE (Total Daily Energy Expenditure) Calculation

### Activity Multipliers
| Activity Level | Multiplier |
|----------------|------------|
| Sedentary | 1.2 |
| Lightly Active | 1.375 |
| Moderately Active | 1.55 |
| Very Active | 1.725 |
| Extremely Active | 1.9 |

### Formula
```
TDEE = BMR × Activity_Multiplier
```

### Example (Moderately Active)
```
TDEE = 1597.9 × 1.55 = 2476.7 calories/day
```

## 3. Calorie Goal Calculation

### Goal Multipliers
| Goal | Multiplier | Description |
|------|------------|-------------|
| Lose Fat | 0.80 | 20% deficit - sustainable fat loss |
| Maintain Weight | 1.0 | No change |
| Gain Weight | 1.15 | 15% surplus - lean mass gain |

### Formula
```
Calorie_Goal = TDEE × Goal_Multiplier
```

### Example (Lose Fat)
```
Calorie_Goal = 2476.7 × 0.80 = 1981.4 calories/day
```

## 4. Protein Calculation

### Base Protein per kg (by Activity Level)
| Activity Level | Protein (g/kg) | Range |
|----------------|----------------|-------|
| Sedentary | 1.5 | 1.4-1.6 |
| Lightly Active | 1.7 | 1.6-1.8 |
| Moderately Active | 1.9 | 1.8-2.0 |
| Very Active | 2.1 | 2.0-2.2 |
| Extremely Active | 2.3 | 2.2-2.4 |

### Goal Adjustments
| Goal | Adjustment | Final Range |
|------|------------|-------------|
| Lose Fat | +0.2 g/kg | Higher protein to preserve muscle |
| Maintain Weight | +0.0 g/kg | Standard protein |
| Gain Weight | +0.1 g/kg | Slightly higher for muscle gain |

### Formula
```
Base_Protein_Per_Kg = Activity_Based_Value
Adjusted_Protein_Per_Kg = Base_Protein_Per_Kg + Goal_Adjustment
Protein_Grams = weight_kg × Adjusted_Protein_Per_Kg
```

### Example (Moderately Active, Lose Fat)
```
Base_Protein_Per_Kg = 1.9
Adjusted_Protein_Per_Kg = 1.9 + 0.2 = 2.1
Protein_Grams = 68.04 × 2.1 = 142.9g
```

## 5. Carbohydrate Calculation

### Fixed Keto Limit
```
Carb_Grams = 30.0g (fixed for all users)
```

## 6. Fat Calculation

### Formula
```
Protein_Calories = Protein_Grams × 4
Carb_Calories = Carb_Grams × 4
Fat_Calories = Calorie_Goal - Protein_Calories - Carb_Calories
Fat_Grams = Fat_Calories ÷ 9
```

### Example
```
Protein_Calories = 142.9 × 4 = 571.6 calories
Carb_Calories = 30 × 4 = 120 calories
Fat_Calories = 1981.4 - 571.6 - 120 = 1289.8 calories
Fat_Grams = 1289.8 ÷ 9 = 143.3g
```

## 7. Complete Example Calculation

### Input Profile
- **Weight**: 150 lbs
- **Height**: 170 cm
- **Age**: 30 years
- **Gender**: Male
- **Activity Level**: Moderately Active
- **Goal**: Lose Fat

### Step-by-Step Calculation

1. **Weight Conversion**:
   ```
   weight_kg = 150 × 0.453592 = 68.04 kg
   ```

2. **BMR Calculation**:
   ```
   BMR = (10 × 68.04) + (6.25 × 170) - (5 × 30) + 5
   BMR = 1597.9 calories/day
   ```

3. **TDEE Calculation**:
   ```
   TDEE = 1597.9 × 1.55 = 2476.7 calories/day
   ```

4. **Calorie Goal**:
   ```
   Calorie_Goal = 2476.7 × 0.80 = 1981.4 calories/day
   ```

5. **Protein Calculation**:
   ```
   Base_Protein_Per_Kg = 1.9 (Moderately Active)
   Adjusted_Protein_Per_Kg = 1.9 + 0.2 = 2.1 (Lose Fat)
   Protein_Grams = 68.04 × 2.1 = 142.9g
   ```

6. **Carbohydrate Calculation**:
   ```
   Carb_Grams = 30.0g
   ```

7. **Fat Calculation**:
   ```
   Protein_Calories = 142.9 × 4 = 571.6 calories
   Carb_Calories = 30 × 4 = 120 calories
   Fat_Calories = 1981.4 - 571.6 - 120 = 1289.8 calories
   Fat_Grams = 1289.8 ÷ 9 = 143.3g
   ```

### Final Macro Targets
- **Protein**: 142.9g (571.6 calories)
- **Net Carbs**: 30.0g (120 calories)
- **Fat**: 143.3g (1289.8 calories)
- **Total Calories**: 1981.4 calories

## 8. Validation Checks

### Protein Validation
- Minimum: 1.4g/kg (Sedentary base)
- Maximum: 2.5g/kg (Extremely Active + Gain Weight)
- Example range for 68kg: 95g - 170g

### Fat Validation
- Must be positive: `Fat_Grams = max(0, Fat_Grams)`
- Should be 60-75% of total calories for keto

### Calorie Validation
- Lose Fat: 70-85% of TDEE
- Maintain: 95-105% of TDEE  
- Gain Weight: 110-120% of TDEE

## 9. Debug Output Format

The app outputs calculations in this format:
```
🔄 DashboardTodayView: Macro goals calculated - Protein: 142.9g, Carbs: 30g, Fat: 143.3g, Calories: 1981
🔄 ProfileView: Calculated macros - Protein: 142.9g, Carbs: 30g, Fat: 143.3g, Calories: 1981
```

## 10. Code Locations

- **DashboardTodayView.swift**: Lines 348-421 (calculateMacroGoals method)
- **ProfileView.swift**: Lines 205-281 (calculateMacroGoals method)
- **EditProfileView.swift**: Lines 188-232 (calculateMacroGoals method)

All three locations now use identical calculation logic for consistency.
