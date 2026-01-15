//
//  NetCarbTrendChart.swift
//  Keto Macro Tracker
//
//  Interactive chart for net carb trend analysis
//

import SwiftUI
import Charts

struct NetCarbTrendChart: View {
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedDataPoint: NetCarbTrend?
    @ObservedObject private var trendManager = NetCarbTrendManager.shared
    
    let goalLimit: Double = 20.0
    let isPremium: Bool
    
    init(isPremium: Bool = true) {
        self.isPremium = isPremium
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Period selector
            periodSelector
            
            // Interactive chart
            chartView
            
            // Insights panel
            if let selected = selectedDataPoint {
                trendInsightCard(selected)
            } else {
                overallInsightsCard
            }
        }
        .onAppear {
            trendManager.updateTrends()
            if selectedDataPoint == nil {
                selectedDataPoint = filteredTrends.last
            }
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            Text("7 Days").tag(TimePeriod.week)
            if isPremium {
                Text("30 Days").tag(TimePeriod.month)
                Text("90 Days").tag(TimePeriod.quarter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onAppear {
            // Reset to week if not premium and selected period is not available
            if !isPremium && selectedPeriod != .week {
                selectedPeriod = .week
            }
        }
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        Chart {
            // Goal zone shading
            if let firstDate = filteredTrends.first?.date, let lastDate = filteredTrends.last?.date {
                RectangleMark(
                    xStart: .value("Start", firstDate),
                    xEnd: .value("End", lastDate),
                    yStart: .value("Goal Min", 0),
                    yEnd: .value("Goal Max", goalLimit)
                )
                .foregroundStyle(Color.green.opacity(0.08))
            }
            
            ForEach(filteredTrends) { trend in
                let isSelected = selectedDataPoint?.id == trend.id
                let areaColor = trend.isKetoFriendly ? Color.green.opacity(0.35) : Color.red.opacity(0.25)
                let lineColor = trend.isKetoFriendly ? Color.green : Color.red
                
                AreaMark(
                    x: .value("Date", trend.date),
                    yStart: .value("Baseline", 0),
                    yEnd: .value("Net Carbs", trend.netCarbs)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [areaColor, Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .opacity(isSelected ? 0.8 : 0.5)
                
                LineMark(
                    x: .value("Date", trend.date),
                    y: .value("Net Carbs", trend.netCarbs)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: isSelected ? 4 : 3))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", trend.date),
                    y: .value("Net Carbs", trend.netCarbs)
                )
                .symbol(isSelected ? .circle : .square)
                .symbolSize(isSelected ? 120 : 60)
                .foregroundStyle(lineColor)
            }
            
            RuleMark(y: .value("Goal", goalLimit))
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("20g Goal")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                }
            
            if let selected = selectedDataPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(Color.primary.opacity(0.2))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
            }
        }
        .frame(height: 300)
        .padding(.horizontal)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: selectedPeriod == .week ? 1 : selectedPeriod == .month ? 3 : 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // Use plotFrame (iOS 17+) - the API changed from plotAreaFrame
                                // plotFrame is now accessed via the geometry proxy
                                let locationX = gesture.location.x
                                guard let date: Date = proxy.value(atX: locationX) else { return }
                                selectedDataPoint = nearestTrend(to: date)
                            }
                    )
            }
        }
    }
    
    // MARK: - Trend Insight Card
    private func trendInsightCard(_ trend: NetCarbTrend) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(trend.date, formatter: dateFormatter)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("\(String(format: "%.1f", trend.netCarbs))g")
                    .font(AppTypography.title2)
                    .foregroundColor(trend.isKetoFriendly ? .green : .red)
                    .fontWeight(.bold)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ketosis Status")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(trend.ketosisStatus.rawValue)
                        .font(AppTypography.callout)
                        .foregroundColor(trend.ketosisStatus.color)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Probability")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(Int(trend.ketosisProbability * 100))%")
                        .font(AppTypography.callout)
                        .foregroundColor(trend.ketosisStatus.color)
                        .fontWeight(.semibold)
                }
            }
            
            Text(trend.ketosisStatus.description)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Overall Insights Card
    private var overallInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Overview")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.text)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(trendManager.currentStreak) days")
                        .font(AppTypography.title3)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Avg")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("\(String(format: "%.1f", trendManager.weeklyAverage))g")
                        .font(AppTypography.title3)
                        .foregroundColor(trendManager.weeklyAverage < 20 ? .green : .orange)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Keto Days")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    let ketoDays = filteredTrends.filter { $0.isKetoFriendly }.count
                    Text("\(ketoDays)/\(filteredTrends.count)")
                        .font(AppTypography.title3)
                        .foregroundColor(ketoDays == filteredTrends.count ? .green : .orange)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    private var filteredTrends: [NetCarbTrend] {
        trendManager.getTrends(for: selectedPeriod)
    }
    
    private func nearestTrend(to date: Date) -> NetCarbTrend? {
        filteredTrends.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Preview
#Preview {
    NetCarbTrendChart(isPremium: true)
        .padding()
}
