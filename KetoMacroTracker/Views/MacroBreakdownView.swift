//
//  MacroBreakdownView.swift
//  Keto Macro Tracker
//
//  Shows detailed breakdown of foods contributing to a specific macro
//

import SwiftUI

// MARK: - Macro Breakdown View
struct MacroBreakdownView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var foodLogManager: FoodLogManager
    
    let macroType: MacroType
    let totalAmount: Double
    let goalAmount: Double
    let color: Color
    
    // Computed property to get foods sorted by macro contribution (descending)
    private var sortedFoods: [LoggedFood] {
        foodLogManager.todaysFoods.sorted { first, second in
            let firstAmount = macroAmount(for: first)
            let secondAmount = macroAmount(for: second)
            return firstAmount > secondAmount
        }
    }
    
    // Helper function to get the macro amount for a specific macro type
    private func macroAmount(for food: LoggedFood) -> Double {
        switch macroType {
        case .protein:
            return food.totalProtein
        case .carbs:
            return food.netCarbs
        case .fat:
            return food.totalFat
        case .calories:
            return food.totalCalories
        }
    }
    
    // Helper function to get macro name
    private var macroName: String {
        switch macroType {
        case .protein: return "Protein"
        case .carbs: return "Net Carbs"
        case .fat: return "Fat"
        case .calories: return "Calories"
        }
    }
    
    // Helper function to get macro unit
    private var macroUnit: String {
        switch macroType {
        case .protein, .carbs, .fat: return "g"
        case .calories: return "cal"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with macro summary
                headerSection
                
                // List of foods sorted by contribution
                foodsListSection
            }
            .navigationTitle("\(macroName) Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Macro circle showing progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(max(totalAmount / goalAmount, 0.0), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(totalAmount))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    Text(macroUnit)
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            // Progress info
            VStack(spacing: 8) {
                Text("\(Int(totalAmount))\(macroUnit) / \(Int(goalAmount))\(macroUnit)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text("\(Int((totalAmount / goalAmount) * 100))% of daily goal")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.secondaryText)
                
                if totalAmount > goalAmount {
                    Text("Over goal by \(Int(totalAmount - goalAmount))\(macroUnit)")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
        }
        .padding()
        .background(AppColors.background)
    }
    
    // MARK: - Foods List Section
    private var foodsListSection: some View {
        List {
            if sortedFoods.isEmpty {
                emptyStateSection
            } else {
                ForEach(sortedFoods) { food in
                    FoodBreakdownRow(
                        food: food,
                        macroType: macroType,
                        macroAmount: macroAmount(for: food),
                        macroUnit: macroUnit,
                        color: color,
                        totalAmount: totalAmount
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: macroIcon)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.6))
            
            Text("No \(macroName.lowercased()) logged today")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            Text("Add some foods to see your \(macroName.lowercased()) breakdown")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // Helper for macro icon
    private var macroIcon: String {
        switch macroType {
        case .protein: return "dumbbell.fill"
        case .carbs: return "leaf.fill"
        case .fat: return "drop.fill"
        case .calories: return "flame.fill"
        }
    }
}

// MARK: - Food Breakdown Row
struct FoodBreakdownRow: View {
    let food: LoggedFood
    let macroType: MacroType
    let macroAmount: Double
    let macroUnit: String
    let color: Color
    let totalAmount: Double
    
    private var percentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (macroAmount / totalAmount) * 100
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Food icon (you can enhance this with food-specific icons)
            Text(foodIcon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(food.food.description)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                
                Text("\(String(format: "%.1f", food.servings)) servings")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", macroAmount))\(macroUnit)")
                    .font(AppTypography.headline)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
    
    // Simple food icon based on food name (you can enhance this)
    private var foodIcon: String {
        let name = food.food.description.lowercased()
        
        if name.contains("chicken") || name.contains("turkey") || name.contains("beef") || name.contains("pork") {
            return "🥩"
        } else if name.contains("fish") || name.contains("salmon") || name.contains("tuna") {
            return "🐟"
        } else if name.contains("egg") {
            return "🥚"
        } else if name.contains("cheese") || name.contains("milk") || name.contains("yogurt") {
            return "🧀"
        } else if name.contains("avocado") || name.contains("olive") {
            return "🥑"
        } else if name.contains("nut") || name.contains("almond") || name.contains("walnut") {
            return "🥜"
        } else if name.contains("vegetable") || name.contains("lettuce") || name.contains("spinach") {
            return "🥬"
        } else if name.contains("berry") || name.contains("fruit") {
            return "🍓"
        } else {
            return "🍽️"
        }
    }
}

// MARK: - Macro Type Enum
enum MacroType: Identifiable {
    case protein
    case carbs
    case fat
    case calories
    
    var id: String {
        switch self {
        case .protein: return "protein"
        case .carbs: return "carbs"
        case .fat: return "fat"
        case .calories: return "calories"
        }
    }
}

// MARK: - Preview
#Preview {
    MacroBreakdownView(
        foodLogManager: FoodLogManager.shared,
        macroType: .protein,
        totalAmount: 120.5,
        goalAmount: 160.0,
        color: AppColors.protein
    )
}
