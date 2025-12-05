//
//  WeeklyTrendSummaryView.swift
//  Keto Macro Tracker
//
//  Visualizes week-over-week net carb performance with summaries.
//

import SwiftUI
import Charts

struct WeeklyTrendSummaryView: View {
    let summaries: [WeeklyCarbSummary]
    let weekDelta: Double?
    let goalLimit: Double = 20.0
    
    private var latestSummary: WeeklyCarbSummary? {
        summaries.last
    }
    
    private var deltaDescription: String {
        guard let delta = weekDelta else { return "Need at least two weeks logged." }
        let signed = delta >= 0 ? "+" : ""
        return "\(signed)\(String(format: "%.1f", delta))g vs last week"
    }
    
    private var deltaColor: Color {
        guard let delta = weekDelta else { return AppColors.secondaryText }
        return delta <= 0 ? .green : .orange
    }
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                header
                chart
                weeklyStats
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Trend Overview")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Text(deltaDescription)
                    .font(AppTypography.callout)
                    .foregroundColor(deltaColor)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if let summary = latestSummary {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("This Week")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(String(format: "%.1f", summary.averageNetCarbs))g avg")
                        .font(AppTypography.title3)
                        .foregroundColor(summary.isKetoCompliant ? .green : .orange)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    // MARK: - Chart
    private var chart: some View {
        Chart {
            ForEach(summaries) { summary in
                BarMark(
                    x: .value("Week", summary.weekStart),
                    y: .value("Average Net Carbs", summary.averageNetCarbs)
                )
                .foregroundStyle(summary.isKetoCompliant ? Color.green : Color.orange)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(Int(summary.averageNetCarbs.rounded()))g")
                        .font(AppTypography.caption)
                        .foregroundColor(summary.isKetoCompliant ? .green : .orange)
                        .padding(.bottom, 4)
                }
            }
            
            RuleMark(y: .value("Goal", goalLimit))
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                .annotation(position: .trailing) {
                    Text("20g goal")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                }
        }
        .frame(height: 220)
        .chartXAxis {
            AxisMarks(values: summaries.map { $0.weekStart }) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let dateValue = value.as(Date.self) {
                        Text(weekLabel(from: dateValue))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - Weekly Stats
    private var weeklyStats: some View {
        HStack(spacing: 16) {
            if let latest = latestSummary {
                statItem(
                    title: "Keto Days",
                    value: "\(latest.ketoDays)/\(latest.totalDays)",
                    subtitle: "In ketosis"
                )
                
                statItem(
                    title: "Compliance",
                    value: "\(Int(latest.complianceRate * 100))%",
                    subtitle: "Goal adherence"
                )
            }
            
            if let previous = summaries.dropLast().last {
                let change = latestSummary?.averageNetCarbs ?? 0 - previous.averageNetCarbs
                statItem(
                    title: "Trend",
                    value: String(format: "%@%.1f", change >= 0 ? "+" : "", change),
                    subtitle: "Week over week",
                    color: change <= 0 ? .green : .orange
                )
            }
        }
    }
    
    private func statItem(title: String, value: String, subtitle: String, color: Color = AppColors.text) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(color)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func weekLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: date) ?? date
        return "\(formatter.string(from: date))\n\(formatter.string(from: end))"
    }
}

#Preview {
    let summaries = [
        WeeklyCarbSummary(weekStart: Date().addingTimeInterval(-21*24*3600), averageNetCarbs: 22, ketoDays: 4, totalDays: 7),
        WeeklyCarbSummary(weekStart: Date().addingTimeInterval(-14*24*3600), averageNetCarbs: 18, ketoDays: 6, totalDays: 7),
        WeeklyCarbSummary(weekStart: Date().addingTimeInterval(-7*24*3600), averageNetCarbs: 19, ketoDays: 5, totalDays: 7),
        WeeklyCarbSummary(weekStart: Date(), averageNetCarbs: 16, ketoDays: 6, totalDays: 6)
    ]
    
    WeeklyTrendSummaryView(summaries: summaries, weekDelta: -3.0)
        .padding()
}



