//
//  MealFiltersView.swift
//  Keto Macro Tracker
//
//  View for filtering meal suggestions
//

import SwiftUI

struct MealFiltersView: View {
    @Binding var selectedCategory: MealCategory?
    @Binding var maxPrepTime: Int?
    @Binding var difficulty: DifficultyLevel?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Meal Category", selection: $selectedCategory) {
                        Text("All Categories").tag(MealCategory?.none)
                        ForEach(MealCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(MealCategory?.some(category))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Prep Time") {
                    Picker("Maximum Prep Time", selection: $maxPrepTime) {
                        Text("Any Time").tag(Int?.none)
                        Text("15 minutes").tag(Int?.some(15))
                        Text("30 minutes").tag(Int?.some(30))
                        Text("45 minutes").tag(Int?.some(45))
                        Text("60 minutes").tag(Int?.some(60))
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Difficulty") {
                    Picker("Difficulty Level", selection: $difficulty) {
                        Text("Any Level").tag(DifficultyLevel?.none)
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(DifficultyLevel?.some(level))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategory = nil
                        maxPrepTime = nil
                        difficulty = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MealFiltersView(
        selectedCategory: .constant(.breakfast),
        maxPrepTime: .constant(30),
        difficulty: .constant(.easy)
    )
}

