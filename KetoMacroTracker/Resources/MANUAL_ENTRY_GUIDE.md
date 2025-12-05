# Manual Food Entry Guide

## Overview
The Manual Food Entry feature handles **three separate measurements**:
1. **Amount you're eating NOW** (what you're logging today)
2. **Nutrition label data** (what the package says the macros are for)
3. **Quick Add serving size** (standardized size for future use)

This allows you to eat 50g, enter data from a 56g label, and save it as 100g in Quick Add - all automatically calculated!

## The Three Measurements

### 1. Amount You're Eating Now
- **What it is**: The actual quantity you're consuming today
- **Example**: 50g
- **Purpose**: Determines what gets logged to your diary today

### 2. Nutrition Label Data
- **What it is**: The serving size that the nutrition facts represent
- **Example**: 56g (from the package label)
**Purpose**: Tells the app what the macros you entered are FOR

### 3. Quick Add Serving Size
- **What it is**: Your standardized serving size for future reference
- **Example**: 100g
- **Purpose**: Makes it easier to use this food again later

## How It Works

### Example: Eating 50g from a 56g package, saving as 100g

**Input:**
1. Food name: Chicken Breast
2. Eating: **50g**
3. Label data for: **56g**
4. Macros (per 56g from label):
   - Protein: 17g
   - Carbs: 0g
   - Fat: 2g
5. Quick Add save as: **100g**

**Step 1: Convert label macros to Quick Add serving**
- Conversion ratio: 100g ÷ 56g = 1.786
- Converted macros (per 100g):
  - Protein: 17g × 1.786 = 30.4g
  - Carbs: 0g × 1.786 = 0g
  - Fat: 2g × 1.786 = 3.6g

**Step 2: Calculate how much you ate**
- You ate: 50g
- Quick Add serving: 100g
- Servings: 50g ÷ 100g = 0.5

**Step 3: Log to diary**
- 0.5 × (30.4g protein, 0g carbs, 3.6g fat)
- **Logged today**: 15.2g protein, 0g carbs, 1.8g fat

**Step 4: Save to Quick Add**
- **Saved**: "Chicken Breast" = 30.4g protein per 100g
- **Next time**: You can quickly add any amount (25g, 50g, 150g, etc.)

## Form Layout

```
📝 Food Information
   • Food name: [Chicken Breast]

📊 Amount You're Eating Now
   • Eating: [50] [g ▼]

📊 Nutrition Label Data
   • Data is for: [56] [g ▼]

📈 Macronutrients
   • Protein: [17] g  (from the 56g label)
   • Fat: [2] g
   • Total Carbs: [0] g
   • Fiber, Sugar Alcohols, Calories (optional)

💾 Quick Add (Optional)
   • Toggle: Save to Quick Add
   • Category: [Protein ▼]
   • Save as: [100] [g ▼]
```

## Real-World Examples

### Example 1: Package with 56g serving, eating 50g, save as 100g

**Scenario**: You have a chicken breast package. The label says "56g per serving: 17g protein, 2g fat". You ate 50g and want to save it as 100g portions.

**Input**:
- Eating: 50g
- Label data for: 56g
- Protein: 17g, Fat: 2g, Carbs: 0g
- Quick Add: 100g

**Calculation**:
- Convert to 100g: 17g × (100/56) = 30.4g protein
- You ate: 50g ÷ 100g = 0.5 servings
- Logged: 0.5 × 30.4g = 15.2g protein

### Example 2: Eating exactly what's on the label

**Scenario**: Package says "1 cup = 5g protein". You ate 1 cup, save as 1 cup.

**Input**:
- Eating: 1 cup
- Label data for: 1 cup
- Protein: 5g
- Quick Add: 1 cup

**Calculation**:
- No conversion needed (label = quick add)
- You ate: 1 ÷ 1 = 1 serving
- Logged: 5g protein

### Example 3: Eating less than label, different Quick Add size

**Scenario**: Label says "2 oz = 6g protein". You ate 1 oz, want to save as 100g.

**Input**:
- Eating: 1 oz
- Label data for: 2 oz
- Protein: 6g
- Quick Add: 100g

**Result**:
- Different units (oz vs g) - needs manual attention
- System will default to 1:1 ratio
- **Tip**: Use matching units for accuracy

## Tips for Best Results

### 1. **Match Units When Possible**
✅ Good: Eating 50g, Label 56g, Quick Add 100g (all grams)
❌ Avoid: Eating 2oz, Label 56g, Quick Add 100g (mixed units)

### 2. **Use Label Serving Size**
- Enter "Data is for" exactly as shown on the package
- This ensures accurate macro conversion

### 3. **Standardize Quick Add Sizes**
- **Meats/Fish**: 100g is standard
- **Items (eggs)**: 1 item
- **Liquids**: 1 cup or 100ml
- **Spices/Oils**: 1 tbsp

### 4. **When to Skip Quick Add**
- Restaurant meals (one-time)
- Unusual combinations
- Foods you won't eat again

### 5. **Per 100g Strategy**
For foods without labels:
- Set "Label data for": 100g
- Enter macros per 100g (lookup online)
- Set "Quick Add": 100g
- Enter any amount for "Eating"

## Calculation Reference

### Formula:
```
1. Conversion Ratio = Quick Add Size ÷ Label Size
2. Converted Macros = Label Macros × Conversion Ratio
3. Servings Eaten = Amount Eating ÷ Quick Add Size
4. Logged Macros = Converted Macros × Servings Eaten
```

### Example:
```
Given:
- Eating: 50g
- Label: 56g with 17g protein
- Quick Add: 100g

Calculate:
1. Ratio = 100 ÷ 56 = 1.786
2. Converted = 17 × 1.786 = 30.4g per 100g
3. Servings = 50 ÷ 100 = 0.5
4. Logged = 30.4 × 0.5 = 15.2g protein
```

## Supported Units

- **g** (grams) - recommended for most foods
- **oz** (ounces)
- **cup** (cups)
- **tbsp** (tablespoons)
- **tsp** (teaspoons)
- **ml** (milliliters)
- **item** (items/pieces)

**Note**: For accurate calculations, all three measurements should use the same unit (e.g., all grams).