//
//  APIUsageTracker.swift
//  Keto Macro Tracker
//
//  Tracks API usage for monitoring and analytics
//

import Foundation

struct APIUsageEvent: Codable {
    let timestamp: Date
    let apiType: String // "USDA" or "OpenFoodFacts"
    let query: String
    let success: Bool
    let errorType: String?
    let responseTime: TimeInterval?
}

class APIUsageTracker: ObservableObject {
    static let shared = APIUsageTracker()
    
    private var usageEvents: [APIUsageEvent] = []
    private let maxEventsToStore = 1000 // Keep last 1000 events
    private let userDefaultsKey = "APIUsageEvents"
    
    private init() {
        loadUsageEvents()
    }
    
    // MARK: - Public Methods
    
    func trackUSDARequest(query: String, success: Bool, errorType: String? = nil, responseTime: TimeInterval? = nil) {
        let event = APIUsageEvent(
            timestamp: Date(),
            apiType: "USDA",
            query: query,
            success: success,
            errorType: errorType,
            responseTime: responseTime
        )
        addEvent(event)
        
        if !success, let error = errorType {
            print("📊 API Usage: USDA request failed - \(error)")
        }
    }
    
    func trackOpenFoodFactsRequest(query: String, success: Bool, errorType: String? = nil, responseTime: TimeInterval? = nil) {
        let event = APIUsageEvent(
            timestamp: Date(),
            apiType: "OpenFoodFacts",
            query: query,
            success: success,
            errorType: errorType,
            responseTime: responseTime
        )
        addEvent(event)
    }
    
    func trackRateLimit() {
        let event = APIUsageEvent(
            timestamp: Date(),
            apiType: "USDA",
            query: "RATE_LIMIT",
            success: false,
            errorType: "rateLimitExceeded",
            responseTime: nil
        )
        addEvent(event)
        print("📊 API Usage: Rate limit event logged")
    }
    
    // MARK: - Statistics
    
    func getUsageStats() -> APIUsageStats {
        let last24Hours = usageEvents.filter { 
            $0.timestamp > Date().addingTimeInterval(-24 * 60 * 60)
        }
        
        let usdaRequests = last24Hours.filter { $0.apiType == "USDA" }
        let offRequests = last24Hours.filter { $0.apiType == "OpenFoodFacts" }
        let rateLimitEvents = last24Hours.filter { $0.errorType == "rateLimitExceeded" }
        
        let usdaSuccess = usdaRequests.filter { $0.success }.count
        let usdaFailed = usdaRequests.filter { !$0.success }.count
        
        return APIUsageStats(
            totalUSDARequests: usdaRequests.count,
            successfulUSDARequests: usdaSuccess,
            failedUSDARequests: usdaFailed,
            totalOpenFoodFactsRequests: offRequests.count,
            rateLimitEvents: rateLimitEvents.count,
            averageResponseTime: calculateAverageResponseTime(events: last24Hours)
        )
    }
    
    func exportUsageData() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(usageEvents),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        
        return jsonString
    }
    
    // MARK: - Private Methods
    
    private func addEvent(_ event: APIUsageEvent) {
        usageEvents.append(event)
        
        // Keep only last N events
        if usageEvents.count > maxEventsToStore {
            usageEvents = Array(usageEvents.suffix(maxEventsToStore))
        }
        
        saveUsageEvents()
    }
    
    private func calculateAverageResponseTime(events: [APIUsageEvent]) -> TimeInterval? {
        let eventsWithTime = events.compactMap { $0.responseTime }
        guard !eventsWithTime.isEmpty else { return nil }
        return eventsWithTime.reduce(0, +) / Double(eventsWithTime.count)
    }
    
    private func saveUsageEvents() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(usageEvents) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadUsageEvents() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let events = try? decoder.decode([APIUsageEvent].self, from: data) {
            usageEvents = events
        }
    }
}

struct APIUsageStats {
    let totalUSDARequests: Int
    let successfulUSDARequests: Int
    let failedUSDARequests: Int
    let totalOpenFoodFactsRequests: Int
    let rateLimitEvents: Int
    let averageResponseTime: TimeInterval?
    
    var successRate: Double {
        guard totalUSDARequests > 0 else { return 0 }
        return Double(successfulUSDARequests) / Double(totalUSDARequests)
    }
    
    var formattedStats: String {
        var stats = "📊 API Usage Statistics (Last 24 Hours):\n"
        stats += "USDA Requests: \(totalUSDARequests) (\(successfulUSDARequests) successful, \(failedUSDARequests) failed)\n"
        stats += "OpenFoodFacts Requests: \(totalOpenFoodFactsRequests)\n"
        stats += "Rate Limit Events: \(rateLimitEvents)\n"
        stats += "Success Rate: \(String(format: "%.1f", successRate * 100))%\n"
        if let avgTime = averageResponseTime {
            stats += "Average Response Time: \(String(format: "%.2f", avgTime))s"
        }
        return stats
    }
}

