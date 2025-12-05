//
//  NotificationManager.swift
//  Keto Macro Tracker
//
//  Manages smart notifications and reminders
//

import Foundation
import UserNotifications

enum NotificationType: String {
    case mealReminder = "meal_reminder"
    case hydrationAlert = "hydration_alert"
    case carbWarning = "carb_warning"
    case macroProgress = "macro_progress"
    case weeklyWeighIn = "weekly_weigh_in"
}

struct NotificationSettings: Codable {
    var mealRemindersEnabled: Bool = true
    var hydrationAlertsEnabled: Bool = true
    var carbWarningsEnabled: Bool = true
    var macroProgressEnabled: Bool = true
    var weeklyWeighInEnabled: Bool = false
    
    var breakfastTime: Date {
        get {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            // Store hour and minute separately
        }
    }
    var breakfastHour: Int = 8
    var breakfastMinute: Int = 0
    var lunchHour: Int = 12
    var lunchMinute: Int = 30
    var dinnerHour: Int = 18
    var dinnerMinute: Int = 0
    
    var hydrationInterval: Int = 2 // hours between hydration reminders
    var carbWarningThreshold: Double = 0.8 // 80% of carb goal
    var macroProgressThresholds: [Double] = [0.75, 0.90, 1.0] // 75%, 90%, 100%
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var settings = NotificationSettings()
    
    private let settingsKey = "NotificationSettings"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        loadSettings()
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification authorization granted")
                self.scheduleAllNotifications()
            } else {
                print("❌ Notification authorization denied")
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleAllNotifications() {
        cancelAllNotifications()
        
        if settings.mealRemindersEnabled {
            scheduleMealReminders()
        }
        
        if settings.hydrationAlertsEnabled {
            scheduleHydrationAlerts()
        }
        
        // Carb warnings and macro progress are event-based, not scheduled
        // They're triggered when food is logged
    }
    
    private func scheduleMealReminders() {
        // Breakfast
        scheduleRepeatingNotification(
            identifier: "\(NotificationType.mealReminder.rawValue)_breakfast",
            title: "Breakfast Time! 🍳",
            body: "Don't forget to log your breakfast to stay on track with your keto goals.",
            hour: settings.breakfastHour,
            minute: settings.breakfastMinute
        )
        
        // Lunch
        scheduleRepeatingNotification(
            identifier: "\(NotificationType.mealReminder.rawValue)_lunch",
            title: "Lunch Time! 🥗",
            body: "Time to log your lunch and keep your macros balanced.",
            hour: settings.lunchHour,
            minute: settings.lunchMinute
        )
        
        // Dinner
        scheduleRepeatingNotification(
            identifier: "\(NotificationType.mealReminder.rawValue)_dinner",
            title: "Dinner Time! 🍽️",
            body: "Log your dinner to complete your daily macro tracking.",
            hour: settings.dinnerHour,
            minute: settings.dinnerMinute
        )
    }
    
    private func scheduleHydrationAlerts() {
        // Schedule hydration reminders every X hours from 8 AM to 8 PM
        let startHour = 8
        let endHour = 20
        let interval = settings.hydrationInterval
        
        var hour = startHour
        var reminderCount = 0
        
        while hour < endHour {
            scheduleRepeatingNotification(
                identifier: "\(NotificationType.hydrationAlert.rawValue)_\(reminderCount)",
                title: "Stay Hydrated! 💧",
                body: "Keto requires extra hydration. Don't forget to drink water!",
                hour: hour,
                minute: 0
            )
            
            hour += interval
            reminderCount += 1
        }
    }
    
    private func scheduleRepeatingNotification(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "KETO_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled notification: \(identifier)")
            }
        }
    }
    
    // MARK: - Event-Based Notifications
    
    func checkCarbWarning(currentCarbs: Double, carbGoal: Double) {
        guard settings.carbWarningsEnabled else { return }
        
        let threshold = carbGoal * settings.carbWarningThreshold
        
        if currentCarbs >= threshold && currentCarbs < carbGoal {
            sendNotification(
                identifier: NotificationType.carbWarning.rawValue,
                title: "⚠️ Approaching Carb Limit",
                body: "You're at \(String(format: "%.0f", (currentCarbs / carbGoal) * 100))% of your carb goal. Be mindful of your remaining carbs!",
                delay: 0
            )
        }
    }
    
    func checkMacroProgress(current: Double, goal: Double, macroType: String) {
        guard settings.macroProgressEnabled else { return }
        
        let progress = current / goal
        
        for threshold in settings.macroProgressThresholds {
            if progress >= threshold && progress < threshold + 0.05 {
                let percentage = Int(threshold * 100)
                sendNotification(
                    identifier: "\(NotificationType.macroProgress.rawValue)_\(macroType)_\(percentage)",
                    title: "🎉 \(percentage)% \(macroType) Goal Reached!",
                    body: "You've reached \(percentage)% of your \(macroType) goal. Keep it up!",
                    delay: 0
                )
                break // Only send one notification per threshold
            }
        }
    }
    
    func checkHydrationReminder(currentWater: Double, waterGoal: Double) {
        guard settings.hydrationAlertsEnabled else { return }
        
        let progress = currentWater / waterGoal
        
        // Remind if less than 50% by 2 PM
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 14 && progress < 0.5 {
            sendNotification(
                identifier: "\(NotificationType.hydrationAlert.rawValue)_afternoon",
                title: "💧 Hydration Reminder",
                body: "You're at \(String(format: "%.0f", progress * 100))% of your water goal. Time to hydrate!",
                delay: 1.0 // Minimum 1 second delay required
            )
        }
    }
    
    private func sendNotification(identifier: String, title: String, body: String, delay: TimeInterval) {
        // Ensure delay is at least 1 second (UNTimeIntervalNotificationTrigger requirement)
        guard delay > 0 else {
            print("⚠️ Cannot schedule notification with delay <= 0")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "KETO_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all notifications")
    }
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Settings
    
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
        saveSettings()
        scheduleAllNotifications()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return
        }
        settings = decoded
    }
}

