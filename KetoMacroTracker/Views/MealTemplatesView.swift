//
//  MealTemplatesView.swift
//  Keto Macro Tracker
//
//  View for managing and using meal templates
//

import SwiftUI

struct MealTemplatesView: View {
    @StateObject private var customMealManager = CustomMealManager.shared
    @EnvironmentObject var foodLogManager: FoodLogManager
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var showingTemplatePicker = false
    @State private var selectedTemplate: CustomMeal? = nil
    @State private var servings: Double = 1.0
    
    private var filteredTemplates: [CustomMeal] {
        let templates = customMealManager.getTemplates(limit: 50)
        if searchText.isEmpty {
            return templates
        } else {
            return templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.secondaryText)
                    
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(10)
                .padding()
                
                // Templates list
                if filteredTemplates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(searchText.isEmpty ? "No Templates" : "No Results")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        Text(searchText.isEmpty ? 
                             "Save custom meals as templates for quick access" :
                             "Try a different search term")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(filteredTemplates) { template in
                        Button(action: {
                            selectedTemplate = template
                            servings = 1.0
                            showingTemplatePicker = true
                        }) {
                            MealTemplateRow(template: template)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                customMealManager.removeTemplate(template)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Meal Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                if let template = selectedTemplate {
                    TemplateServingsPickerView(
                        template: template,
                        servings: $servings,
                        onAdd: { servings in
                            customMealManager.quickAddTemplate(template, servings: servings, to: foodLogManager)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
}

struct MealTemplateRow: View {
    let template: CustomMeal
    @StateObject private var customMealManager = CustomMealManager.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.category.icon)
                .foregroundColor(template.category.color)
                .font(.title3)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                
                HStack {
                    Text(template.category.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(template.prepTime) min")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                nutritionBadge("P", value: String(format: "%.0f", template.totalProtein), color: AppColors.protein)
                nutritionBadge("C", value: String(format: "%.0f", template.netCarbs), color: AppColors.carbs)
                nutritionBadge("F", value: String(format: "%.0f", template.totalFat), color: AppColors.fat)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                customMealManager.removeTemplate(template)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
        }
    }
    
    private func nutritionBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(minWidth: 24)
    }
}

struct TemplateServingsPickerView: View {
    let template: CustomMeal
    @Binding var servings: Double
    let onAdd: (Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Template info
                VStack(alignment: .leading, spacing: 12) {
                    Text(template.name)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.text)
                    
                    Text(template.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                    
                    // Nutrition preview
                    HStack(spacing: 16) {
                        nutritionPreview("Protein", value: template.totalProtein * servings, unit: "g", color: AppColors.protein)
                        nutritionPreview("Carbs", value: template.netCarbs * servings, unit: "g", color: AppColors.carbs)
                        nutritionPreview("Fat", value: template.totalFat * servings, unit: "g", color: AppColors.fat)
                        nutritionPreview("Cal", value: template.totalCalories * servings, unit: "", color: AppColors.calories)
                    }
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
                
                // Servings selector
                VStack(spacing: 16) {
                    Text("Servings")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    HStack(spacing: 20) {
                        ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { value in
                            Button(action: {
                                servings = value
                            }) {
                                Text("\(String(format: "%.1f", value))x")
                                    .font(AppTypography.headline)
                                    .foregroundColor(servings == value ? .white : AppColors.text)
                                    .frame(width: 60, height: 44)
                                    .background(servings == value ? AppColors.primary : AppColors.secondaryBackground)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Stepper("Servings: \(String(format: "%.1f", servings))", value: $servings, in: 0.25...10, step: 0.25)
                        .font(AppTypography.body)
                }
                .padding()
                
                Spacer()
                
                // Add button
                Button(action: {
                    onAdd(servings)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Food Log")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Add Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func nutritionPreview(_ title: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(AppTypography.caption)
                    .foregroundColor(color)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppTypography.caption)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MealTemplatesView()
        .environmentObject(FoodLogManager.shared)
}

