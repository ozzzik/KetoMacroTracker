//
//  AnalyticsManager.swift
//  Keto Macro Tracker
//
//  Advanced analytics and correlation analysis
//

import Foundation

struct CorrelationResult {
    let metric1: String
    let metric2: String
    let correlation: Double // -1.0 to 1.0
    let strength: CorrelationStrength
    let description: String
}

enum CorrelationStrength: String {
    case strong = "Strong"
    case moderate = "Moderate"
    case weak = "Weak"
    case none = "None"
}

struct MacroEfficiencyScore {
    let overall: Double // 0-100
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    let consistency: Double // How consistent you are day-to-day
    let description: String
}

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let historicalDataManager = HistoricalDataManager.shared
    
    private init() {}
    
    // MARK: - Correlation Analysis
    
    func analyzeCorrelations(days: Int = 30) -> [CorrelationResult] {
        let allSummaries = historicalDataManager.dailySummaries.sorted { $0.date > $1.date }
        let summaries = Array(allSummaries.prefix(days))
        guard summaries.count >= 7 else { return [] } // Need at least 7 data points
        
        var correlations: [CorrelationResult] = []
        
        // Net Carbs vs Weight (if weight data available)
        if let weightCorrelation = calculateCorrelation(
            x: summaries.map { $0.netCarbs },
            y: summaries.map { $0.date.timeIntervalSince1970 },
            label1: "Net Carbs",
            label2: "Time"
        ) {
            correlations.append(weightCorrelation)
        }
        
        // Protein vs Calories
        if let proteinCalCorrelation = calculateCorrelation(
            x: summaries.map { $0.totalProtein },
            y: summaries.map { $0.totalCalories },
            label1: "Protein",
            label2: "Calories"
        ) {
            correlations.append(proteinCalCorrelation)
        }
        
        // Fat vs Calories
        if let fatCalCorrelation = calculateCorrelation(
            x: summaries.map { $0.totalFat },
            y: summaries.map { $0.totalCalories },
            label1: "Fat",
            label2: "Calories"
        ) {
            correlations.append(fatCalCorrelation)
        }
        
        // Net Carbs vs Fat (inverse relationship for keto)
        if let carbsFatCorrelation = calculateCorrelation(
            x: summaries.map { $0.netCarbs },
            y: summaries.map { $0.totalFat },
            label1: "Net Carbs",
            label2: "Fat"
        ) {
            correlations.append(carbsFatCorrelation)
        }
        
        return correlations
    }
    
    private func calculateCorrelation(x: [Double], y: [Double], label1: String, label2: String) -> CorrelationResult? {
        guard x.count == y.count && x.count >= 3 else { return nil }
        
        let n = Double(x.count)
        let xMean = x.reduce(0, +) / n
        let yMean = y.reduce(0, +) / n
        
        let numerator = zip(x, y).map { (xVal, yVal) in (xVal - xMean) * (yVal - yMean) }.reduce(0, +)
        let xVariance = x.map { pow($0 - xMean, 2) }.reduce(0, +)
        let yVariance = y.map { pow($0 - yMean, 2) }.reduce(0, +)
        
        let denominator = sqrt(xVariance * yVariance)
        guard denominator != 0 else { return nil }
        
        let correlation = numerator / denominator
        
        let strength: CorrelationStrength
        let absCorrelation = abs(correlation)
        if absCorrelation >= 0.7 {
            strength = .strong
        } else if absCorrelation >= 0.4 {
            strength = .moderate
        } else if absCorrelation >= 0.2 {
            strength = .weak
        } else {
            strength = .none
        }
        
        let description = generateCorrelationDescription(correlation, strength, label1, label2)
        
        return CorrelationResult(
            metric1: label1,
            metric2: label2,
            correlation: correlation,
            strength: strength,
            description: description
        )
    }
    
    private func generateCorrelationDescription(_ correlation: Double, _ strength: CorrelationStrength, _ label1: String, _ label2: String) -> String {
        let direction = correlation > 0 ? "increases" : "decreases"
        let absValue = abs(correlation)
        
        switch strength {
        case .strong:
            return "Strong relationship: As \(label1) \(direction), \(label2) tends to \(direction) (\(String(format: "%.0f", absValue * 100))% correlation)"
        case .moderate:
            return "Moderate relationship: \(label1) and \(label2) show some connection (\(String(format: "%.0f", absValue * 100))% correlation)"
        case .weak:
            return "Weak relationship: Slight connection between \(label1) and \(label2) (\(String(format: "%.0f", absValue * 100))% correlation)"
        case .none:
            return "No significant relationship between \(label1) and \(label2)"
        }
    }
    
    // MARK: - Macro Efficiency Scoring
    
    func calculateMacroEfficiency(days: Int = 7) -> MacroEfficiencyScore {
        let allSummaries = historicalDataManager.dailySummaries.sorted { $0.date > $1.date }
        let summaries = Array(allSummaries.prefix(days))
        guard !summaries.isEmpty else {
            return MacroEfficiencyScore(
                overall: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                calories: 0,
                consistency: 0,
                description: "Not enough data"
            )
        }
        
        let profile = ProfileManager.shared.profile
        let goals = calculateMacroGoals(profile: profile)
        
        // Calculate individual macro scores
        let proteinScores = summaries.map { min(1.0, $0.totalProtein / goals.protein) }
        let carbScores = summaries.map { max(0, 1.0 - ($0.netCarbs / goals.carbs)) } // Lower is better for carbs
        let fatScores = summaries.map { min(1.0, $0.totalFat / goals.fat) }
        let calorieScores = summaries.map { min(1.0, $0.totalCalories / goals.calories) }
        
        let avgProtein = proteinScores.reduce(0, +) / Double(proteinScores.count) * 100
        let avgCarbs = carbScores.reduce(0, +) / Double(carbScores.count) * 100
        let avgFat = fatScores.reduce(0, +) / Double(fatScores.count) * 100
        let avgCalories = calorieScores.reduce(0, +) / Double(calorieScores.count) * 100
        
        // Calculate consistency (lower variance = higher consistency)
        let proteinVariance = calculateVariance(proteinScores)
        let carbVariance = calculateVariance(carbScores)
        let fatVariance = calculateVariance(fatScores)
        let avgVariance = (proteinVariance + carbVariance + fatVariance) / 3.0
        let consistency = max(0, 100 - (avgVariance * 200)) // Convert variance to 0-100 scale
        
        // Overall score (weighted average)
        let overall = (avgProtein * 0.3 + avgCarbs * 0.3 + avgFat * 0.2 + avgCalories * 0.2)
        
        let description = generateEfficiencyDescription(overall, consistency)
        
        return MacroEfficiencyScore(
            overall: overall,
            protein: avgProtein,
            carbs: avgCarbs,
            fat: avgFat,
            calories: avgCalories,
            consistency: consistency,
            description: description
        )
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func generateEfficiencyDescription(_ overall: Double, _ consistency: Double) -> String {
        var parts: [String] = []
        
        if overall >= 90 {
            parts.append("Excellent macro tracking")
        } else if overall >= 75 {
            parts.append("Good macro adherence")
        } else if overall >= 60 {
            parts.append("Moderate macro tracking")
        } else {
            parts.append("Room for improvement")
        }
        
        if consistency >= 80 {
            parts.append("with high consistency")
        } else if consistency >= 60 {
            parts.append("with moderate consistency")
        } else {
            parts.append("with variable consistency")
        }
        
        return parts.joined(separator: ", ")
    }
    
    // MARK: - Trend Analysis
    
    func analyzeTrends(days: Int = 7) -> [String] {
        let allSummaries = historicalDataManager.dailySummaries.sorted { $0.date > $1.date }
        let summaries = Array(allSummaries.prefix(days))
        guard summaries.count >= 3 else { return ["Not enough data for trend analysis"] }
        
        var insights: [String] = []
        
        // Net carbs trend
        let netCarbs = summaries.map { $0.netCarbs }
        if let trend = calculateTrend(netCarbs) {
            if trend > 0.1 {
                insights.append("⚠️ Net carbs are trending upward - consider reducing carb intake")
            } else if trend < -0.1 {
                insights.append("✅ Net carbs are trending downward - great for ketosis")
            }
        }
        
        // Protein trend
        let protein = summaries.map { $0.totalProtein }
        if let trend = calculateTrend(protein) {
            if trend > 0.1 {
                insights.append("📈 Protein intake is increasing")
            } else if trend < -0.1 {
                insights.append("📉 Protein intake is decreasing")
            }
        }
        
        // Consistency check
        let carbVariance = calculateVariance(netCarbs)
        if carbVariance < 0.1 {
            insights.append("🎯 Very consistent net carb intake - excellent for keto")
        } else if carbVariance > 0.3 {
            insights.append("⚠️ High variability in net carbs - try to maintain consistency")
        }
        
        return insights
    }
    
    private func calculateTrend(_ values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        let n = Double(values.count)
        let xMean = (n - 1) / 2.0
        let yMean = values.reduce(0, +) / n
        
        let numerator = values.enumerated().map { Double($0.offset) * ($0.element - yMean) }.reduce(0, +)
        let denominator = (0..<values.count).map { pow(Double($0) - xMean, 2) }.reduce(0, +)
        
        guard denominator != 0 else { return nil }
        return numerator / denominator
    }
}

