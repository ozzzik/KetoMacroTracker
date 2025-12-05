//
//  LeftoverTrackingView.swift
//  Keto Macro Tracker
//
//  View for tracking and finishing leftover meals
//

import SwiftUI

struct LeftoverTrackingView: View {
    @StateObject private var leftoverManager = LeftoverManager.shared
    @EnvironmentObject var foodLogManager: FoodLogManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingFinishConfirmation = false
    @State private var selectedLeftover: Leftover? = nil
    @State private var servings: Double = 1.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if leftoverManager.leftovers.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(leftoverManager.leftovers) { leftover in
                            leftoverCard(leftover)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Leftovers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Finish Leftover", isPresented: $showingFinishConfirmation) {
            VStack {
                Text("Servings:")
                TextField("1.0", value: $servings, format: .number)
                    .keyboardType(.decimalPad)
            }
            Button("Cancel", role: .cancel) { }
            Button("Finish") {
                if let leftover = selectedLeftover {
                    leftoverManager.finishLeftover(leftover, servings: servings, to: foodLogManager)
                }
            }
        } message: {
            if let leftover = selectedLeftover {
                Text("Add \(leftover.name) to today's food log?")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.system(size: 64))
                .foregroundColor(AppColors.secondaryText)
            
            Text("No Leftovers")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
            
            Text("Save partial meals as leftovers to finish them later")
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func leftoverCard(_ leftover: Leftover) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(leftover.name)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        HStack {
                            Text(formatDate(leftover.dateCreated))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            
                            if leftover.daysUntilExpiration > 0 {
                                Text("•")
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("\(leftover.daysUntilExpiration) days left")
                                    .font(AppTypography.caption)
                                    .foregroundColor(leftover.daysUntilExpiration <= 1 ? .red : AppColors.secondaryText)
                            } else {
                                Text("• Expired")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        leftoverManager.removeLeftover(leftover)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Foods list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(leftover.foods) { food in
                        HStack {
                            Text(food.food.description)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", food.servings)) servings")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(AppColors.background)
                .cornerRadius(8)
                
                // Nutrition summary
                HStack(spacing: 16) {
                    nutritionBadge("Protein", value: String(format: "%.1f", leftover.totalNutrition.protein), unit: "g", color: AppColors.protein)
                    nutritionBadge("Carbs", value: String(format: "%.1f", leftover.totalNutrition.carbs), unit: "g", color: AppColors.carbs)
                    nutritionBadge("Fat", value: String(format: "%.1f", leftover.totalNutrition.fat), unit: "g", color: AppColors.fat)
                    nutritionBadge("Cal", value: String(format: "%.0f", leftover.totalNutrition.calories), unit: "", color: AppColors.calories)
                }
                
                // Finish button
                Button(action: {
                    selectedLeftover = leftover
                    servings = 1.0
                    showingFinishConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish Leftover")
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
            }
        }
    }
    
    private func nutritionBadge(_ title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 2) {
                Text(value)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    LeftoverTrackingView()
        .environmentObject(FoodLogManager.shared)
}

