//
//  DashboardTodayView.swift
//  Keto Macro Tracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI

struct DashboardTodayView: View {
    @EnvironmentObject var foodLogManager: FoodLogManager
    @EnvironmentObject var quickAddManager: QuickAddManager
    @EnvironmentObject var guidedTourManager: GuidedTourManager
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var waterManager = WaterIntakeManager.shared
    @StateObject private var fastingManager = FastingManager.shared
    @State private var showingFoodSearch = false
    @State private var showingQuickAdd = false
    @State private var showingFastingTimer = false
    @State private var showingPaywall = false
    @StateObject private var dashboardTutorialManager = DashboardTutorialManager.shared
    @State private var selectedMacroType: MacroType = .protein
    @State private var selectedMacroTypeForSheet: MacroType? = nil
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase
    
    // Computed properties from food log
    private var protein: Double { foodLogManager.totalProtein }
    private var carbs: Double { foodLogManager.netCarbs }
    private var fat: Double { foodLogManager.totalFat }
    private var calories: Double { foodLogManager.totalCalories }
    
    // Macro balance warnings - time-aware and actionable
    private var macroBalanceWarnings: [MacroWarning] {
        var warnings: [MacroWarning] = []
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let mealsRemaining: Double
        switch currentHour {
        case 0..<10: mealsRemaining = 3.0  // Morning: 3 meals left
        case 10..<15: mealsRemaining = 2.0 // Afternoon: 2 meals left
        case 15..<21: mealsRemaining = 1.0 // Evening: 1 meal left
        default: mealsRemaining = 0.5      // Late night: minimal time left
        }
        
        // Calculate projected macros based on current pace
        let hoursElapsed = Double(max(currentHour, 1))
        let hoursRemaining = 24.0 - hoursElapsed
        let projectedFat = hoursRemaining > 0 ? fat + (fat / hoursElapsed) * hoursRemaining : fat
        
        // Only show warnings if they're actionable or critical
        
        // CRITICAL: Carb limit exceeded (always show)
        if carbs > macroGoals.carbs * 1.1 {
            warnings.append(MacroWarning(
                type: .carbsTooHigh,
                message: "Net carbs are \(String(format: "%.0f", carbs))g, exceeding your keto limit of \(String(format: "%.0f", macroGoals.carbs))g",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        }
        // WARNING: Approaching carb limit (only show if >80% and it's actionable)
        else if carbs > macroGoals.carbs * 0.8 && currentHour >= 12 {
            warnings.append(MacroWarning(
                type: .carbsTooHigh,
                message: "Approaching carb limit (\(String(format: "%.0f", carbs))g / \(String(format: "%.0f", macroGoals.carbs))g). Plan remaining meals carefully.",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ))
        }
        
        // Check fat:protein ratio (only show if problematic AND actionable)
        let proteinCalories = protein * 4
        let fatCalories = fat * 9
        let fatToProteinRatio = fatCalories / max(proteinCalories, 1)
        
        // Only warn about ratio if it's actually low AND we're past breakfast (when it matters)
        if fatToProteinRatio < 1.2 && fatCalories > 0 && currentHour >= 12 && mealsRemaining <= 2 {
            warnings.append(MacroWarning(
                type: .fatTooLow,
                message: "Fat:Protein ratio is low (\(String(format: "%.1f", fatToProteinRatio)):1). Focus on higher-fat options for remaining meals.",
                icon: "drop.fill",
                color: .orange
            ))
        }
        
        // Check for very high protein (only if significantly over AND actionable)
        if protein > macroGoals.protein * 1.3 && currentHour >= 12 {
            warnings.append(MacroWarning(
                type: .proteinTooHigh,
                message: "Protein is very high (\(String(format: "%.0f", protein))g). Excess protein can convert to glucose. Focus on fat for remaining meals.",
                icon: "arrow.up.circle.fill",
                color: .orange
            ))
        }
        
        // Check projected fat intake (only show if projected to be low AND it's actionable)
        // Only show this warning if we're past lunch and projected to be significantly under
        if projectedFat < macroGoals.fat * 0.7 && currentHour >= 14 && mealsRemaining >= 1 {
            let fatNeeded = macroGoals.fat - fat
            warnings.append(MacroWarning(
                type: .fatTooLow,
                message: "On track for \(String(format: "%.0f", projectedFat))g fat (goal: \(String(format: "%.0f", macroGoals.fat))g). Aim to add ~\(String(format: "%.0f", fatNeeded))g fat in remaining meals.",
                icon: "drop.fill",
                color: .orange
            ))
        }
        
        // Early day context: Show helpful info instead of warnings
        if warnings.isEmpty && currentHour < 12 && (fat < macroGoals.fat * 0.3 || protein < macroGoals.protein * 0.3) {
            // Don't show warnings early in the day - it's normal to be low
            // The progress rings already show this information
        }
        
        return warnings
    }
    
    // Computed properties for macro goals from profile
    private var macroGoals: (protein: Double, carbs: Double, fat: Double, calories: Double) {
        let goals = calculateMacroGoals(profile: profileManager.profile)
        print("🔄 DashboardTodayView: Macro goals calculated - Protein: \(String(format: "%.1f", goals.protein))g, Carbs: \(goals.carbs)g, Fat: \(String(format: "%.1f", goals.fat))g, Calories: \(String(format: "%.0f", goals.calories))")
        return goals
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Quick Stats Card
                        quickStatsSection
                        
                        // Water Tracking
                        waterTrackingSection
                        
                        // Fasting Timer
                        if fastingManager.currentSession != nil {
                            fastingWidgetSection
                        }
                        
                        // Macro Balance Warnings
                        if !macroBalanceWarnings.isEmpty {
                            macroBalanceWarningsSection
                        }
                        
                        // Progress Rings
                        progressRingsSection
                        
                        // Food Log
                        foodLogSection
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, geometry.size.width > 768 ? 32 : 16)
                    .padding(.top, 16)
                }
                .background(AppColors.background)
            }
            .navigationBarHidden(true)
        }
        .adaptiveSheet(isPresented: $showingFoodSearch) {
            FoodSearchView(foodLogManager: foodLogManager, quickAddManager: quickAddManager)
        }
        .adaptiveSheet(isPresented: $showingQuickAdd) {
            QuickAddView(quickAddManager: quickAddManager, foodLogManager: foodLogManager)
        }
        .adaptiveSheet(item: $selectedMacroTypeForSheet) { macroType in
            MacroBreakdownView(
                foodLogManager: foodLogManager,
                macroType: macroType,
                totalAmount: macroAmount(for: macroType),
                goalAmount: macroGoal(for: macroType),
                color: macroColor(for: macroType)
            )
        }
        .adaptiveSheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .adaptiveSheet(isPresented: $showingFastingTimer) {
            FastingTimerView()
        }
        .overlay {
            if dashboardTutorialManager.isShowing {
                DashboardTutorialView(isPresented: Binding(
                    get: { dashboardTutorialManager.isShowing },
                    set: { newValue in
                        if !newValue {
                            dashboardTutorialManager.hide()
                        }
                    }
                ))
            }
        }
        .overlay(
            GuidedTourOverlay(tourManager: guidedTourManager)
        )
        .onAppear {
            // Show paywall on first launch if not subscribed
            let hasSeenPaywall = UserDefaults.standard.bool(forKey: "hasSeenPaywall")
            let hasLoggedFood = !foodLogManager.todaysFoods.isEmpty
            
            if !hasSeenPaywall && !hasLoggedFood && !subscriptionManager.isPremiumActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingPaywall = true
                    UserDefaults.standard.set(true, forKey: "hasSeenPaywall")
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Dismiss sheets when app goes to background to prevent trait collection crashes
            if newPhase == .background || newPhase == .inactive {
                showingFoodSearch = false
                showingQuickAdd = false
                showingPaywall = false
                selectedMacroTypeForSheet = nil
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.text)
                    
                    Text(DateFormatter.todayDate.string(from: Date()))
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Star button for favorites
                    Button(action: {
                        showingQuickAdd = true
                    }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Quick Add Favorites")
                    .accessibilityHint("Tap to open your saved favorite foods")
                    .tourAction(buttonId: "star_button", tourManager: guidedTourManager)
                    
                    // Plus button for adding new items
                        Button(action: {
                            // Always allow food search - paywall is shown separately on first launch
                            showingFoodSearch = true
                        }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [.red, .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Add Food")
                    .accessibilityHint("Tap to search and add new foods to your log")
                    .tourAction(buttonId: "plus_button", tourManager: guidedTourManager)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Stats")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(spacing: 12) {
                    quickStatRow(
                        title: "Calories",
                        current: calories,
                        goal: macroGoals.calories,
                        unit: "",
                        color: AppColors.calories
                    )
                    
                    quickStatRow(
                        title: "Net Carbs",
                        current: carbs,
                        goal: macroGoals.carbs,
                        unit: "g",
                        color: AppColors.carbs
                    )
                    
                    quickStatRow(
                        title: "Protein",
                        current: protein,
                        goal: macroGoals.protein,
                        unit: "g",
                        color: AppColors.protein
                    )
                    
                    quickStatRow(
                        title: "Fat",
                        current: fat,
                        goal: macroGoals.fat,
                        unit: "g",
                        color: AppColors.fat
                    )
                }
            }
        }
    }
    
    // MARK: - Water Tracking Section
    private var waterTrackingSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Hydration")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", waterManager.todaysWaterIntake)) / \(String(format: "%.0f", waterManager.dailyGoal)) cups")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * waterManager.progress, height: 12)
                    }
                }
                .frame(height: 12)
                
                // Quick add buttons
                HStack(spacing: 12) {
                    ForEach([1.0, 2.0, 3.0], id: \.self) { amount in
                        Button(action: {
                            waterManager.addWater(amount)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                Text("\(String(format: "%.0f", amount)) cup\(amount == 1 ? "" : "s")")
                                    .font(AppTypography.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Remove button
                    if waterManager.todaysWaterIntake > 0 {
                        Button(action: {
                            waterManager.removeWater(1.0)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Fasting Widget Section
    private var fastingWidgetSection: some View {
        AppCard {
            Button(action: {
                showingFastingTimer = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        
                        Text("Fasting")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                        
                        Spacer()
                        
                        if let session = fastingManager.currentSession {
                            Text(session.type.displayName)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fastingManager.getFormattedCurrentDuration())
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                                .monospacedDigit()
                            
                            if let remaining = fastingManager.getFormattedRemainingTime() {
                                Text("\(remaining) remaining")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Macro Balance Warnings Section
    private var macroBalanceWarningsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Macro Balance")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                }
                
                ForEach(macroBalanceWarnings, id: \.type) { warning in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: warning.icon)
                            .foregroundColor(warning.color)
                            .font(.caption)
                            .frame(width: 20)
                        
                        Text(warning.message)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Progress Rings Section
    private var progressRingsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Progress Rings")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 20) {
                    Button(action: {
                        selectedMacroType = .protein
                        selectedMacroTypeForSheet = .protein
                    }) {
                        progressRing(
                            value: safeDivision(protein, macroGoals.protein),
                            title: "P",
                            percentage: safePercentage(protein, macroGoals.protein),
                            color: AppColors.protein
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Protein breakdown")
                    .accessibilityHint("Tap to see which foods contribute most to your protein intake")
                    
                    Button(action: {
                        selectedMacroType = .carbs
                        selectedMacroTypeForSheet = .carbs
                    }) {
                        progressRing(
                            value: safeDivision(carbs, macroGoals.carbs),
                            title: "C",
                            percentage: safePercentage(carbs, macroGoals.carbs),
                            color: AppColors.carbs
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Carbs breakdown")
                    .accessibilityHint("Tap to see which foods contribute most to your carb intake")
                    
                    Button(action: {
                        selectedMacroType = .fat
                        selectedMacroTypeForSheet = .fat
                    }) {
                        progressRing(
                            value: safeDivision(fat, macroGoals.fat),
                            title: "F",
                            percentage: safePercentage(fat, macroGoals.fat),
                            color: AppColors.fat
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Fat breakdown")
                    .accessibilityHint("Tap to see which foods contribute most to your fat intake")
                    
                    Button(action: {
                        selectedMacroType = .calories
                        selectedMacroTypeForSheet = .calories
                    }) {
                        progressRing(
                            value: safeDivision(calories, macroGoals.calories),
                            title: "Cal",
                            percentage: safePercentage(calories, macroGoals.calories),
                            color: AppColors.calories
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Calories breakdown")
                    .accessibilityHint("Tap to see which foods contribute most to your calorie intake")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Food Log Section
    private var foodLogSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Food Log")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(spacing: 12) {
                    if foodLogManager.todaysFoods.isEmpty {
                        // Empty state - no foods logged yet
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.secondaryText.opacity(0.5))
                            
                            Text("No foods logged today")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("Tap the + button to add your first food")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                    } else {
                        // Show logged foods
                        ForEach(foodLogManager.todaysFoods) { loggedFood in
                            HStack {
                                foodLogItem(
                                    icon: FoodIconMapper.getIcon(for: loggedFood.food),
                                    name: loggedFood.food.description,
                                    serving: "\(String(format: "%.1f", loggedFood.servings)) servings",
                                    protein: Int(loggedFood.totalProtein),
                                    carbs: Int(loggedFood.netCarbs),
                                    fat: Int(loggedFood.totalFat),
                                    calories: Int(loggedFood.totalCalories)
                                )
                                
                                Button(action: {
                                    foodLogManager.removeFood(loggedFood)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func safeDivision(_ numerator: Double, _ denominator: Double) -> Double {
        guard denominator != 0 && denominator.isFinite && numerator.isFinite else {
            return 0.0
        }
        let result = numerator / denominator
        return result.isFinite ? result : 0.0
    }
    
    private func safePercentage(_ numerator: Double, _ denominator: Double) -> Int {
        let percentage = safeDivision(numerator, denominator) * 100
        let safePercentage = percentage.isFinite ? percentage : 0.0
        return Int(min(max(safePercentage, 0), 100)) // Clamp between 0 and 100
    }
    
    // MARK: - Helper Views
    private func quickStatRow(title: String, current: Double, goal: Double, unit: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(Int(current))\(unit) / \(Int(goal))\(unit)")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.secondaryText)
                
                Text("\(safePercentage(current, goal))%")
                    .font(AppTypography.callout)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private func progressRing(value: Double, title: String, percentage: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(max(value.isFinite ? value : 0.0, 0.0), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(percentage)%")
                    .font(AppTypography.caption)
                    .foregroundColor(color)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.text)
                .fontWeight(.medium)
        }
    }
    
    private func foodLogItem(icon: String, name: String, serving: String, protein: Int, carbs: Int, fat: Int, calories: Int) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Text(serving)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(calories) cal")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.calories)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Text("P:\(protein)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.protein)
                    
                    Text("C:\(carbs)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.carbs)
                    
                    Text("F:\(fat)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.fat)
                }
            }
        }
        .padding(12)
        .background(AppColors.background)
        .cornerRadius(8)
    }
    
    // Uses shared calculateMacroGoals function from Utils/MacroCalculations.swift
    
    // MARK: - Macro Helper Functions
    private func macroAmount(for macroType: MacroType) -> Double {
        switch macroType {
        case .protein: return protein
        case .carbs: return carbs
        case .fat: return fat
        case .calories: return calories
        }
    }
    
    private func macroGoal(for macroType: MacroType) -> Double {
        switch macroType {
        case .protein: return macroGoals.protein
        case .carbs: return macroGoals.carbs
        case .fat: return macroGoals.fat
        case .calories: return macroGoals.calories
        }
    }
    
    private func macroColor(for macroType: MacroType) -> Color {
        switch macroType {
        case .protein: return AppColors.protein
        case .carbs: return AppColors.carbs
        case .fat: return AppColors.fat
        case .calories: return AppColors.calories
        }
    }
}

// MARK: - Macro Warning Model
enum MacroWarningType {
    case carbsTooHigh
    case fatTooLow
    case proteinTooHigh
}

struct MacroWarning: Identifiable {
    let id = UUID()
    let type: MacroWarningType
    let message: String
    let icon: String
    let color: Color
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let todayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}

#Preview {
    DashboardTodayView()
}
