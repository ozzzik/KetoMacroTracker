//
//  PredictiveInsightsManager.swift
//  Keto Macro Tracker
//
//  Predictive insights and goal timeline predictions
//

import Foundation

struct GoalPrediction {
    let goalType: GoalType
    let currentValue: Double
    let targetValue: Double
    let predictedWeeks: Double?
    let confidence: Double // 0-1
    let message: String
    let recommendations: [String]
}

enum GoalType {
    case weightLoss
    case weightGain
    case macroConsistency
    case ketosisMaintenance
}

class PredictiveInsightsManager: ObservableObject {
    static let shared = PredictiveInsightsManager()
    
    private let historicalDataManager = HistoricalDataManager.shared
    private let profileManager = ProfileManager.shared
    
    private init() {}
    
    // MARK: - Goal Timeline Predictions
    
    func predictGoalTimeline(goalType: GoalType) -> GoalPrediction? {
        let profile = profileManager.profile
        // Get recent summaries (last 30 days)
        let allSummaries = historicalDataManager.dailySummaries.sorted { $0.date > $1.date }
        let summaries = Array(allSummaries.prefix(30))
        
        guard !summaries.isEmpty else {
            return GoalPrediction(
                goalType: goalType,
                currentValue: 0,
                targetValue: 0,
                predictedWeeks: nil,
                confidence: 0,
                message: "Not enough data for predictions. Log at least 7 days of data.",
                recommendations: []
            )
        }
        
        switch goalType {
        case .weightLoss:
            return predictWeightLoss(summaries: summaries, profile: profile)
        case .weightGain:
            return predictWeightGain(summaries: summaries, profile: profile)
        case .macroConsistency:
            return predictMacroConsistency(summaries: summaries, profile: profile)
        case .ketosisMaintenance:
            return predictKetosisMaintenance(summaries: summaries)
        }
    }
    
    private func predictWeightLoss(summaries: [DailySummary], profile: UserProfile) -> GoalPrediction? {
        guard profile.goal == "Lose Fat" else { return nil }
        
        // Calculate average daily calorie deficit
        let goals = calculateMacroGoals(profile: profile)
        let avgCalories = summaries.map { $0.totalCalories }.reduce(0, +) / Double(summaries.count)
        let dailyDeficit = goals.calories - avgCalories
        
        // Estimate weight loss rate (1 lb = ~3500 calories)
        let weeklyDeficit = dailyDeficit * 7
        let lbsPerWeek = weeklyDeficit / 3500.0
        
        // Assume target is 10% body weight loss (or use a reasonable default)
        let currentWeight = profile.weight
        let targetWeight = currentWeight * 0.9 // 10% loss
        let weightToLose = currentWeight - targetWeight
        
        let predictedWeeks = lbsPerWeek > 0 ? weightToLose / lbsPerWeek : nil
        let confidence = min(1.0, Double(summaries.count) / 30.0) // More data = higher confidence
        
        let message: String
        if let weeks = predictedWeeks, weeks > 0 {
            message = "At your current rate, you could reach your goal in approximately \(String(format: "%.0f", weeks)) weeks."
        } else {
            message = "You're currently at or above your calorie goal. To lose weight, aim for a calorie deficit."
        }
        
        let recommendations = generateWeightLossRecommendations(avgCalories: avgCalories, goal: goals.calories, dailyDeficit: dailyDeficit)
        
        return GoalPrediction(
            goalType: .weightLoss,
            currentValue: currentWeight,
            targetValue: targetWeight,
            predictedWeeks: predictedWeeks,
            confidence: confidence,
            message: message,
            recommendations: recommendations
        )
    }
    
    private func predictWeightGain(summaries: [DailySummary], profile: UserProfile) -> GoalPrediction? {
        guard profile.goal == "Gain Weight" else { return nil }
        
        let goals = calculateMacroGoals(profile: profile)
        let avgCalories = summaries.map { $0.totalCalories }.reduce(0, +) / Double(summaries.count)
        let dailySurplus = avgCalories - goals.calories
        
        let weeklySurplus = dailySurplus * 7
        let lbsPerWeek = weeklySurplus / 3500.0
        
        let currentWeight = profile.weight
        let targetWeight = currentWeight * 1.1 // 10% gain
        let weightToGain = targetWeight - currentWeight
        
        let predictedWeeks = lbsPerWeek > 0 ? weightToGain / lbsPerWeek : nil
        let confidence = min(1.0, Double(summaries.count) / 30.0)
        
        let message: String
        if let weeks = predictedWeeks, weeks > 0 {
            message = "At your current rate, you could reach your goal in approximately \(String(format: "%.0f", weeks)) weeks."
        } else {
            message = "You're currently at or below your calorie goal. To gain weight, aim for a calorie surplus."
        }
        
        let recommendations = generateWeightGainRecommendations(avgCalories: avgCalories, goal: goals.calories, dailySurplus: dailySurplus)
        
        return GoalPrediction(
            goalType: .weightGain,
            currentValue: currentWeight,
            targetValue: targetWeight,
            predictedWeeks: predictedWeeks,
            confidence: confidence,
            message: message,
            recommendations: recommendations
        )
    }
    
    private func predictMacroConsistency(summaries: [DailySummary], profile: UserProfile) -> GoalPrediction? {
        let goals = calculateMacroGoals(profile: profile)
        
        // Calculate consistency scores
        let proteinScores = summaries.map { min(1.0, $0.totalProtein / goals.protein) }
        let carbScores = summaries.map { max(0, 1.0 - ($0.netCarbs / goals.carbs)) }
        let fatScores = summaries.map { min(1.0, $0.totalFat / goals.fat) }
        
        let avgProtein = proteinScores.reduce(0, +) / Double(proteinScores.count)
        let avgCarbs = carbScores.reduce(0, +) / Double(carbScores.count)
        let avgFat = fatScores.reduce(0, +) / Double(fatScores.count)
        
        let overallConsistency = (avgProtein + avgCarbs + avgFat) / 3.0
        
        // Predict when user will reach 90% consistency
        let currentConsistency = overallConsistency
        let targetConsistency = 0.9
        
        // Simple linear projection (assuming improvement trend)
        let improvementRate = calculateImprovementRate(proteinScores + carbScores + fatScores)
        let weeksToTarget = improvementRate > 0 ? (targetConsistency - currentConsistency) / improvementRate : nil
        
        let confidence = min(1.0, Double(summaries.count) / 30.0)
        
        let message: String
        if let weeks = weeksToTarget, weeks > 0 {
            message = "At your current improvement rate, you could reach 90% macro consistency in approximately \(String(format: "%.0f", weeks)) weeks."
        } else {
            message = "Your macro consistency is \(String(format: "%.0f", currentConsistency * 100))%. Keep tracking to improve!"
        }
        
        let recommendations = generateConsistencyRecommendations(
            proteinScore: avgProtein,
            carbScore: avgCarbs,
            fatScore: avgFat
        )
        
        return GoalPrediction(
            goalType: .macroConsistency,
            currentValue: currentConsistency,
            targetValue: targetConsistency,
            predictedWeeks: weeksToTarget,
            confidence: confidence,
            message: message,
            recommendations: recommendations
        )
    }
    
    private func predictKetosisMaintenance(summaries: [DailySummary]) -> GoalPrediction? {
        let netCarbs = summaries.map { $0.netCarbs }
        let avgNetCarbs = netCarbs.reduce(0, +) / Double(netCarbs.count)
        let daysInKetosis = netCarbs.filter { $0 <= 20.0 }.count
        let ketosisRate = Double(daysInKetosis) / Double(netCarbs.count)
        
        // Predict weeks to maintain 90%+ ketosis rate
        let targetRate = 0.9
        let improvementRate = calculateImprovementRate(netCarbs.map { $0 <= 20.0 ? 1.0 : 0.0 })
        let weeksToTarget = improvementRate > 0 ? (targetRate - ketosisRate) / improvementRate : nil
        
        let confidence = min(1.0, Double(summaries.count) / 30.0)
        
        let message: String
        if let weeks = weeksToTarget, weeks > 0 {
            message = "At your current rate, you could maintain 90%+ ketosis in approximately \(String(format: "%.0f", weeks)) weeks."
        } else if ketosisRate >= 0.9 {
            message = "Excellent! You're maintaining ketosis \(String(format: "%.0f", ketosisRate * 100))% of the time."
        } else {
            message = "Your current ketosis rate is \(String(format: "%.0f", ketosisRate * 100))%. Keep net carbs under 20g daily."
        }
        
        let recommendations = generateKetosisRecommendations(avgNetCarbs: avgNetCarbs, ketosisRate: ketosisRate)
        
        return GoalPrediction(
            goalType: .ketosisMaintenance,
            currentValue: ketosisRate,
            targetValue: targetRate,
            predictedWeeks: weeksToTarget,
            confidence: confidence,
            message: message,
            recommendations: recommendations
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateImprovementRate(_ values: [Double]) -> Double {
        guard values.count >= 7 else { return 0 }
        
        // Simple linear regression to find trend
        let n = Double(values.count)
        let xMean = (n - 1) / 2.0
        let yMean = values.reduce(0, +) / n
        
        let numerator = values.enumerated().map { Double($0.offset) * ($0.element - yMean) }.reduce(0, +)
        let denominator = (0..<values.count).map { pow(Double($0) - xMean, 2) }.reduce(0, +)
        
        guard denominator != 0 else { return 0 }
        return (numerator / denominator) / 7.0 // Convert to per-week rate
    }
    
    private func generateWeightLossRecommendations(avgCalories: Double, goal: Double, dailyDeficit: Double) -> [String] {
        var recommendations: [String] = []
        
        if dailyDeficit < 200 {
            recommendations.append("Increase your calorie deficit by 200-300 calories per day")
        }
        
        if avgCalories > goal {
            recommendations.append("You're above your calorie goal. Consider reducing portion sizes or choosing lower-calorie foods")
        }
        
        recommendations.append("Aim for 1-2 lbs per week for sustainable weight loss")
        recommendations.append("Maintain adequate protein intake to preserve muscle mass")
        
        return recommendations
    }
    
    private func generateWeightGainRecommendations(avgCalories: Double, goal: Double, dailySurplus: Double) -> [String] {
        var recommendations: [String] = []
        
        if dailySurplus < 200 {
            recommendations.append("Increase your calorie intake by 200-300 calories per day")
        }
        
        if avgCalories < goal {
            recommendations.append("You're below your calorie goal. Add healthy fats and protein to increase calories")
        }
        
        recommendations.append("Focus on lean muscle gain with adequate protein and strength training")
        recommendations.append("Aim for 0.5-1 lb per week for healthy weight gain")
        
        return recommendations
    }
    
    private func generateConsistencyRecommendations(proteinScore: Double, carbScore: Double, fatScore: Double) -> [String] {
        var recommendations: [String] = []
        
        if proteinScore < 0.8 {
            recommendations.append("Focus on hitting your protein goal consistently")
        }
        
        if carbScore < 0.8 {
            recommendations.append("Keep net carbs under your daily limit more consistently")
        }
        
        if fatScore < 0.8 {
            recommendations.append("Ensure adequate fat intake to meet your goals")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Great job maintaining consistent macro tracking!")
        }
        
        return recommendations
    }
    
    private func generateKetosisRecommendations(avgNetCarbs: Double, ketosisRate: Double) -> [String] {
        var recommendations: [String] = []
        
        if avgNetCarbs > 20 {
            recommendations.append("Reduce average net carbs to stay under 20g daily")
        }
        
        if ketosisRate < 0.7 {
            recommendations.append("Aim to stay under 20g net carbs at least 5 days per week")
        }
        
        recommendations.append("Track hidden carbs in processed foods and condiments")
        recommendations.append("Focus on whole, unprocessed foods for better carb control")
        
        return recommendations
    }
}

