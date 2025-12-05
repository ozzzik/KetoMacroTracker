//
//  NetCarbTrendManager.swift
//  Keto Macro Tracker
//
//  Manages net carb trend analysis and ketosis insights
//

import Foundation
import SwiftUI

// MARK: - Net Carb Trend Data Structure
struct NetCarbTrend: Identifiable, Codable {
    let id: UUID
    let date: Date
    let netCarbs: Double
    let totalCarbs: Double
    let fiber: Double
    let sugarAlcohols: Double
    let isKetoFriendly: Bool // < 20g net carbs
    let weeklyAverage: Double
    let streakCount: Int
    let goalLimit: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        netCarbs: Double,
        totalCarbs: Double,
        fiber: Double,
        sugarAlcohols: Double,
        isKetoFriendly: Bool,
        weeklyAverage: Double,
        streakCount: Int,
        goalLimit: Double
    ) {
        self.id = id
        self.date = date
        self.netCarbs = netCarbs
        self.totalCarbs = totalCarbs
        self.fiber = fiber
        self.sugarAlcohols = sugarAlcohols
        self.isKetoFriendly = isKetoFriendly
        self.weeklyAverage = weeklyAverage
        self.streakCount = streakCount
        self.goalLimit = goalLimit
    }
    
    // Computed properties
    var ketosisProbability: Double {
        switch netCarbs {
        case 0..<10: return 0.95
        case 10..<20: return 0.85
        case 20..<30: return 0.60
        case 30..<50: return 0.30
        default: return 0.10
        }
    }
    
    var trendDirection: TrendDirection {
        // This would be calculated by comparing with previous days
        // For now, return stable - will be enhanced later
        return .stable
    }
    
    var ketosisStatus: KetosisStatus {
        switch netCarbs {
        case 0..<10: return .optimal
        case 10..<20: return .good
        case 20..<30: return .borderline
        case 30..<50: return .unlikely
        default: return .out
        }
    }
}

enum TrendDirection {
    case improving, declining, stable
}

enum KetosisStatus: String, CaseIterable {
    case optimal = "Optimal Ketosis"
    case good = "Good Ketosis"
    case borderline = "Borderline"
    case unlikely = "Unlikely"
    case out = "Out of Ketosis"
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .good: return .green.opacity(0.8)
        case .borderline: return .yellow
        case .unlikely: return .orange
        case .out: return .red
        }
    }
    
    var description: String {
        switch self {
        case .optimal: return "Excellent! You're in optimal ketosis range."
        case .good: return "Great! You're likely in ketosis."
        case .borderline: return "You're on the edge. Try to stay under 20g."
        case .unlikely: return "You may be out of ketosis. Focus on lower carbs."
        case .out: return "You're likely out of ketosis. Reset and go lower carb."
        }
    }
}

// MARK: - Net Carb Trend Manager
class NetCarbTrendManager: ObservableObject {
    static let shared = NetCarbTrendManager()
    
    @Published var trends: [NetCarbTrend] = []
    @Published var currentStreak: Int = 0
    @Published var weeklyAverage: Double = 0.0
    @Published var monthlyAverage: Double = 0.0
    
    private let historicalDataManager = HistoricalDataManager.shared
    private let profileManager = ProfileManager.shared
    
    private init() {
        loadTrends()
    }
    
    // MARK: - Public Methods
    
    /// Calculate and update trends from historical data
    func updateTrends() {
        // First, ensure today's data is archived to historical data
        let foodLogManager = FoodLogManager.shared
        print("🔍 NetCarbTrendManager Debug - Today's foods: \(foodLogManager.todaysFoods.count)")
        print("🔍 NetCarbTrendManager Debug - Today's net carbs: \(foodLogManager.netCarbs)g")
        
        historicalDataManager.archiveCurrentDay(foodLogManager.todaysFoods)
        
        let historicalData = historicalDataManager.dailySummaries
        print("🔍 NetCarbTrendManager Debug - Historical summaries: \(historicalData.count)")
        
        var newTrends: [NetCarbTrend] = []
        
        // Group data by date
        let groupedData = Dictionary(grouping: historicalData) { data in
            Calendar.current.startOfDay(for: data.date)
        }
        
        print("🔍 NetCarbTrendManager Debug - Grouped data: \(groupedData.count) days")
        
        // Calculate trends for each day
        for (date, dayData) in groupedData.sorted(by: { $0.key < $1.key }) {
            let trend = calculateTrendForDay(date: date, dayData: dayData)
            newTrends.append(trend)
            print("🔍 NetCarbTrendManager Debug - Day \(date): \(trend.netCarbs)g net carbs")
        }
        
        // Apply streak counts and update averages
        let annotatedTrends = applyStreakCounts(to: newTrends)
        updateStreakAndAverages(trends: annotatedTrends)
        
        trends = annotatedTrends
        saveTrends()
        
        print("📊 Updated trends with \(newTrends.count) days of data")
    }
    
    /// Get trends for a specific time period
    func getTrends(for period: TimePeriod) -> [NetCarbTrend] {
        let sortedTrends = trends.sorted { $0.date < $1.date }
        
        switch period {
        case .week:
            return Array(sortedTrends.suffix(7))
        case .month:
            return Array(sortedTrends.suffix(30))
        case .quarter:
            return Array(sortedTrends.suffix(90))
        }
    }
    
    /// Get current ketosis status
    func getCurrentKetosisStatus() -> KetosisStatus {
        guard let todayTrend = trends.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: Date()) 
        }) else {
            return .out
        }
        
        return todayTrend.ketosisStatus
    }
    
    /// Get streak information
    func getStreakInfo() -> (current: Int, longest: Int) {
        let current = currentStreak
        let longest = trends.map { $0.streakCount }.max() ?? 0
        return (current, longest)
    }
    
    /// Weekly summaries for charting (most recent first by default)
    func getWeeklySummaries(limit: Int = 4) -> [WeeklyCarbSummary] {
        let calendar = Calendar.current
        var grouped: [Date: [NetCarbTrend]] = [:]
        
        for trend in trends {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: trend.date)) ?? calendar.startOfDay(for: trend.date)
            grouped[weekStart, default: []].append(trend)
        }
        
        let summaries = grouped
            .map { (weekStart, trends) -> WeeklyCarbSummary in
                let average = trends.reduce(0) { $0 + $1.netCarbs } / Double(trends.count)
                let ketoDays = trends.filter { $0.isKetoFriendly }.count
                return WeeklyCarbSummary(
                    weekStart: weekStart,
                    averageNetCarbs: average,
                    ketoDays: ketoDays,
                    totalDays: trends.count
                )
            }
            .sorted { $0.weekStart < $1.weekStart }
        
        return Array(summaries.suffix(limit))
    }
    
    /// Week-over-week delta (positive = more carbs this week)
    func weekOverWeekDelta() -> Double? {
        let summaries = getWeeklySummaries(limit: 2)
        guard summaries.count == 2 else { return nil }
        let previous = summaries.first!
        let current = summaries.last!
        return current.averageNetCarbs - previous.averageNetCarbs
    }
    
    // MARK: - Helpers
    private func applyStreakCounts(to trends: [NetCarbTrend]) -> [NetCarbTrend] {
        var updated: [NetCarbTrend] = []
        var currentStreak = 0
        for trend in trends.sorted(by: { $0.date < $1.date }) {
            if trend.isKetoFriendly {
                currentStreak += 1
            } else {
                currentStreak = 0
            }
            updated.append(trend.withStreak(currentStreak))
        }
        return updated
    }
    
    // MARK: - Private Methods
    
    private func calculateTrendForDay(date: Date, dayData: [DailySummary]) -> NetCarbTrend {
        let totalNetCarbs = dayData.reduce(0) { $0 + $1.netCarbs }
        let totalCarbs = dayData.reduce(0) { $0 + $1.totalCarbs }
        
        // Calculate fiber and sugar alcohols from foods
        let totalFiber = dayData.reduce(0) { dayTotal, day in
            dayTotal + day.foods.reduce(0) { foodTotal, food in
                foodTotal + (food.food.fiber * food.servings)
            }
        }
        
        let totalSugarAlcohols = dayData.reduce(0) { dayTotal, day in
            dayTotal + day.foods.reduce(0) { foodTotal, food in
                foodTotal + (food.food.sugarAlcohols * food.servings)
            }
        }
        
        let isKetoFriendly = totalNetCarbs < 20.0
        let goalLimit = 20.0 // Standard keto limit
        
        // Calculate weekly average from existing trends
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekData = trends.filter { 
            $0.date >= weekStart && $0.date <= date 
        }
        let weeklyAverage = weekData.isEmpty ? totalNetCarbs : weekData.reduce(0) { $0 + $1.netCarbs } / Double(weekData.count)
        
        return NetCarbTrend(
            date: date,
            netCarbs: totalNetCarbs,
            totalCarbs: totalCarbs,
            fiber: totalFiber,
            sugarAlcohols: totalSugarAlcohols,
            isKetoFriendly: isKetoFriendly,
            weeklyAverage: weeklyAverage,
            streakCount: 0, // Will be calculated in updateStreakAndAverages
            goalLimit: goalLimit
        )
    }
    
    private func updateStreakAndAverages(trends: [NetCarbTrend]) {
        // Calculate current streak
        var streak = 0
        for trend in trends.reversed() {
            if trend.isKetoFriendly {
                streak += 1
            } else {
                break
            }
        }
        currentStreak = streak
        
        // Update averages
        let last7Days = trends.suffix(7)
        weeklyAverage = last7Days.isEmpty ? 0 : last7Days.reduce(0) { $0 + $1.netCarbs } / Double(last7Days.count)
        
        let last30Days = trends.suffix(30)
        monthlyAverage = last30Days.isEmpty ? 0 : last30Days.reduce(0) { $0 + $1.netCarbs } / Double(last30Days.count)
    }
    
    // MARK: - Persistence
    
    private func saveTrends() {
        if let encoded = try? JSONEncoder().encode(trends) {
            UserDefaults.standard.set(encoded, forKey: "NetCarbTrends")
        }
    }
    
    private func loadTrends() {
        guard let data = UserDefaults.standard.data(forKey: "NetCarbTrends"),
              let decoded = try? JSONDecoder().decode([NetCarbTrend].self, from: data) else {
            return
        }
        trends = decoded
    }
}

enum TimePeriod {
    case week, month, quarter
}

// MARK: - Weekly Summary Structure
struct WeeklyCarbSummary: Identifiable, Hashable {
    let id = UUID()
    let weekStart: Date
    let averageNetCarbs: Double
    let ketoDays: Int
    let totalDays: Int
    
    var complianceRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(ketoDays) / Double(totalDays)
    }
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: endDate))"
    }
    
    var isKetoCompliant: Bool {
        averageNetCarbs <= 20.0
    }
}

extension NetCarbTrend {
    func withStreak(_ streak: Int) -> NetCarbTrend {
        NetCarbTrend(
            id: id,
            date: date,
            netCarbs: netCarbs,
            totalCarbs: totalCarbs,
            fiber: fiber,
            sugarAlcohols: sugarAlcohols,
            isKetoFriendly: isKetoFriendly,
            weeklyAverage: weeklyAverage,
            streakCount: streak,
            goalLimit: goalLimit
        )
    }
}
