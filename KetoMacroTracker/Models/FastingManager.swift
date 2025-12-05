//
//  FastingManager.swift
//  Keto Macro Tracker
//
//  Manages intermittent fasting sessions and tracking
//

import Foundation
import SwiftUI

// MARK: - Fasting Session Model
struct FastingSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    let targetDuration: TimeInterval? // in seconds (optional goal)
    let type: FastingType
    
    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
    
    var isActive: Bool {
        return endDate == nil
    }
    
    var formattedDuration: String {
        return FastingManager.formatDuration(duration)
    }
    
    var remainingTime: TimeInterval? {
        guard let target = targetDuration, isActive else { return nil }
        let elapsed = duration
        let remaining = target - elapsed
        return remaining > 0 ? remaining : 0
    }
    
    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        targetDuration: TimeInterval? = nil,
        type: FastingType
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.targetDuration = targetDuration
        self.type = type
    }
}

enum FastingType: String, Codable, CaseIterable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "24:0"
    case custom = "Custom"
    
    var displayName: String {
        return rawValue
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .sixteenEight: return 16 * 3600 // 16 hours
        case .eighteenSix: return 18 * 3600 // 18 hours
        case .twentyFour: return 24 * 3600 // 24 hours
        case .custom: return 16 * 3600 // Default to 16:8
        }
    }
    
    var description: String {
        switch self {
        case .sixteenEight: return "16 hours fasting, 8 hours eating window"
        case .eighteenSix: return "18 hours fasting, 6 hours eating window"
        case .twentyFour: return "24 hours fasting (OMAD)"
        case .custom: return "Custom fasting duration"
        }
    }
}

// MARK: - Fasting Manager
class FastingManager: ObservableObject {
    static let shared = FastingManager()
    
    @Published var currentSession: FastingSession?
    @Published var fastingHistory: [FastingSession] = []
    
    private let userDefaultsKey = "FastingSessions"
    private let currentSessionKey = "CurrentFastingSession"
    
    private init() {
        loadFastingData()
    }
    
    // MARK: - Public Methods
    
    func startFasting(type: FastingType, targetDuration: TimeInterval? = nil) {
        let duration = targetDuration ?? type.defaultDuration
        currentSession = FastingSession(
            startDate: Date(),
            endDate: nil,
            targetDuration: duration,
            type: type
        )
        saveFastingData()
        print("⏱️ Started fasting: \(type.displayName)")
        
        // Update widget
        WidgetDataService.shared.updateWidgetData()
    }
    
    func endFasting() {
        guard var session = currentSession else { return }
        session.endDate = Date()
        
        // Add to history
        fastingHistory.append(session)
        
        // Keep only last 30 days of history
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        fastingHistory = fastingHistory.filter { $0.startDate >= cutoffDate }
        
        currentSession = nil
        saveFastingData()
        print("✅ Ended fasting. Duration: \(session.formattedDuration)")
        
        // Update widget
        WidgetDataService.shared.updateWidgetData()
        
        // Sync to Health if enabled (note: fasting not supported in HealthKit, but we track it)
        if UserDefaults.standard.bool(forKey: "HealthKitAutoSync"),
           let endDate = session.endDate {
            HealthKitManager.shared.saveFastingSession(
                startDate: session.startDate,
                endDate: endDate
            )
        }
    }
    
    func getCurrentDuration() -> TimeInterval {
        guard let session = currentSession else { return 0 }
        return session.duration
    }
    
    func getFormattedCurrentDuration() -> String {
        return FastingManager.formatDuration(getCurrentDuration())
    }
    
    func getRemainingTime() -> TimeInterval? {
        return currentSession?.remainingTime
    }
    
    func getFormattedRemainingTime() -> String? {
        guard let remaining = getRemainingTime() else { return nil }
        return FastingManager.formatDuration(remaining)
    }
    
    func getProgress() -> Double {
        guard let session = currentSession,
              let target = session.targetDuration else { return 0.0 }
        return min(session.duration / target, 1.0)
    }
    
    func getAverageFastingDuration(days: Int = 7) -> TimeInterval {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentSessions = fastingHistory.filter { $0.startDate >= cutoffDate && $0.endDate != nil }
        
        guard !recentSessions.isEmpty else { return 0 }
        
        let totalDuration = recentSessions.reduce(0.0) { $0 + $1.duration }
        return totalDuration / Double(recentSessions.count)
    }
    
    func getStreak() -> Int {
        let calendar = Calendar.current
        let sortedSessions = fastingHistory
            .filter { $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
        
        guard !sortedSessions.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = Date()
        
        for session in sortedSessions {
            let sessionDate = calendar.startOfDay(for: session.startDate)
            let checkDate = calendar.startOfDay(for: currentDate)
            
            if sessionDate == checkDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if sessionDate < checkDate {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Private Methods
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func saveFastingData() {
        // Save current session
        if let session = currentSession,
           let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: currentSessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentSessionKey)
        }
        
        // Save history
        if let encoded = try? JSONEncoder().encode(fastingHistory) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        
        print("💾 Saved fasting data")
    }
    
    private func loadFastingData() {
        // Load current session
        if let data = UserDefaults.standard.data(forKey: currentSessionKey),
           let session = try? JSONDecoder().decode(FastingSession.self, from: data) {
            // Check if session is still active (not older than 48 hours)
            let maxAge: TimeInterval = 48 * 3600
            if session.duration < maxAge && session.endDate == nil {
                currentSession = session
                print("⏱️ Loaded active fasting session: \(session.formattedDuration)")
            } else {
                // Session expired, end it
                if session.endDate == nil {
                    var endedSession = session
                    endedSession.endDate = Date()
                    fastingHistory.append(endedSession)
                }
                currentSession = nil
            }
        }
        
        // Load history
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([FastingSession].self, from: data) {
            fastingHistory = decoded
            print("💾 Loaded \(fastingHistory.count) fasting sessions")
        }
    }
}

