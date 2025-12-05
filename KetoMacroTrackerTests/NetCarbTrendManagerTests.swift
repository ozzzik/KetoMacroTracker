import XCTest
@testable import KetoMacroTracker

final class NetCarbTrendManagerTests: XCTestCase {
    private var manager: NetCarbTrendManager!
    private var originalTrends: [NetCarbTrend] = []
    private var originalCurrentStreak: Int = 0
    private var originalWeeklyAverage: Double = 0
    private var originalMonthlyAverage: Double = 0
    
    override func setUp() {
        super.setUp()
        manager = NetCarbTrendManager.shared
        originalTrends = manager.trends
        originalCurrentStreak = manager.currentStreak
        originalWeeklyAverage = manager.weeklyAverage
        originalMonthlyAverage = manager.monthlyAverage
    }
    
    override func tearDown() {
        manager.trends = originalTrends
        manager.currentStreak = originalCurrentStreak
        manager.weeklyAverage = originalWeeklyAverage
        manager.monthlyAverage = originalMonthlyAverage
        super.tearDown()
    }
    
    func testGetTrendsReturnsLatestSevenDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var mockTrends: [NetCarbTrend] = []
        for offset in 0..<10 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockTrends.append(makeTrend(date: date, netCarbs: Double(offset)))
        }
        
        manager.trends = mockTrends
        
        let weekTrends = manager.getTrends(for: .week)
        
        XCTAssertEqual(weekTrends.count, 7, "Expected exactly seven days of data for the weekly view.")
        
        let expectedFirstDate = calendar.date(byAdding: .day, value: -6, to: today)
        XCTAssertEqual(weekTrends.first?.date, expectedFirstDate, "Weekly slice should begin six days before today.")
        XCTAssertEqual(weekTrends.last?.date, today, "Weekly slice should end on today.")
    }
    
    func testWeeklySummariesAndWeekOverWeekDelta() {
        let calendar = Calendar.current
        guard let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
              let startOfPreviousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfCurrentWeek) else {
            XCTFail("Unable to calculate week boundaries for test fixtures.")
            return
        }
        
        var trends: [NetCarbTrend] = []
        for day in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: day, to: startOfPreviousWeek) else { continue }
            let netCarbs: Double = day < 7 ? 15 : 25
            trends.append(makeTrend(date: date, netCarbs: netCarbs))
        }
        
        manager.trends = trends
        
        let summaries = manager.getWeeklySummaries(limit: 2)
        XCTAssertEqual(summaries.count, 2, "Expected summaries for the previous and current week.")
        
        let previousWeek = summaries.first!
        XCTAssertTrue(previousWeek.isKetoCompliant, "First week should be considered keto compliant.")
        XCTAssertEqual(previousWeek.averageNetCarbs, 15, accuracy: 0.001)
        XCTAssertEqual(previousWeek.ketoDays, 7)
        XCTAssertEqual(previousWeek.totalDays, 7)
        XCTAssertEqual(previousWeek.complianceRate, 1.0, accuracy: 0.001)
        
        let currentWeek = summaries.last!
        XCTAssertFalse(currentWeek.isKetoCompliant, "Second week should exceed keto target.")
        XCTAssertEqual(currentWeek.averageNetCarbs, 25, accuracy: 0.001)
        XCTAssertEqual(currentWeek.ketoDays, 0)
        XCTAssertEqual(currentWeek.totalDays, 7)
        
        guard let delta = manager.weekOverWeekDelta() else {
            XCTFail("Expected a valid week-over-week delta with two weeks of data.")
            return
        }
        XCTAssertEqual(delta, 10, accuracy: 0.001, "Delta should reflect the 10g increase between weeks.")
    }
    
    // MARK: - Helpers
    
    private func makeTrend(date: Date, netCarbs: Double) -> NetCarbTrend {
        NetCarbTrend(
            date: date,
            netCarbs: netCarbs,
            totalCarbs: netCarbs,
            fiber: 0,
            sugarAlcohols: 0,
            isKetoFriendly: netCarbs < 20,
            weeklyAverage: netCarbs,
            streakCount: 0,
            goalLimit: 20
        )
    }
}



