//
//  NotificationSettingsView.swift
//  Keto Macro Tracker
//
//  View for configuring smart notifications
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var localSettings: NotificationSettings
    
    init() {
        _localSettings = State(initialValue: NotificationManager.shared.settings)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Meal Reminders
                Section(header: Text("Meal Reminders")) {
                    Toggle("Enable Meal Reminders", isOn: $localSettings.mealRemindersEnabled)
                    
                    if localSettings.mealRemindersEnabled {
                        HStack {
                            Text("Breakfast")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = localSettings.breakfastHour
                                    components.minute = localSettings.breakfastMinute
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    localSettings.breakfastHour = components.hour ?? 8
                                    localSettings.breakfastMinute = components.minute ?? 0
                                }
                            ), displayedComponents: .hourAndMinute)
                        }
                        
                        HStack {
                            Text("Lunch")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = localSettings.lunchHour
                                    components.minute = localSettings.lunchMinute
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    localSettings.lunchHour = components.hour ?? 12
                                    localSettings.lunchMinute = components.minute ?? 30
                                }
                            ), displayedComponents: .hourAndMinute)
                        }
                        
                        HStack {
                            Text("Dinner")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: {
                                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = localSettings.dinnerHour
                                    components.minute = localSettings.dinnerMinute
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    localSettings.dinnerHour = components.hour ?? 18
                                    localSettings.dinnerMinute = components.minute ?? 0
                                }
                            ), displayedComponents: .hourAndMinute)
                        }
                    }
                }
                
                // Hydration Alerts
                Section(header: Text("Hydration Alerts")) {
                    Toggle("Enable Hydration Reminders", isOn: $localSettings.hydrationAlertsEnabled)
                    
                    if localSettings.hydrationAlertsEnabled {
                        Stepper("Remind every \(localSettings.hydrationInterval) hours", value: $localSettings.hydrationInterval, in: 1...4)
                    }
                }
                
                // Carb Warnings
                Section(header: Text("Carb Warnings")) {
                    Toggle("Warn When Approaching Carb Limit", isOn: $localSettings.carbWarningsEnabled)
                    
                    if localSettings.carbWarningsEnabled {
                        HStack {
                            Text("Warning Threshold")
                            Spacer()
                            Text("\(Int(localSettings.carbWarningThreshold * 100))%")
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Slider(value: $localSettings.carbWarningThreshold, in: 0.5...0.95, step: 0.05)
                    }
                }
                
                // Macro Progress
                Section(header: Text("Macro Progress")) {
                    Toggle("Celebrate Progress Milestones", isOn: $localSettings.macroProgressEnabled)
                    
                    if localSettings.macroProgressEnabled {
                        Text("Get notified at 75%, 90%, and 100% of your macro goals")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                // Weekly Weigh-In
                Section(header: Text("Weekly Weigh-In")) {
                    Toggle("Weekly Weigh-In Reminder", isOn: $localSettings.weeklyWeighInEnabled)
                    
                    if localSettings.weeklyWeighInEnabled {
                        Text("Get reminded every week to log your weight")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        notificationManager.updateSettings(localSettings)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}

