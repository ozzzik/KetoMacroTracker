//
//  KetoMacroWidget.swift
//  Keto Macro Tracker
//
//  Widget extension for home screen quick view
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct MacroEntry: TimelineEntry {
    let date: Date
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let caloriesGoal: Double
    let waterIntake: Double
    let waterGoal: Double
    let fastingDuration: String?
    let isFasting: Bool
}

// MARK: - Widget Provider
struct MacroProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry(
            date: Date(),
            protein: 120,
            carbs: 15,
            fat: 80,
            calories: 1800,
            proteinGoal: 150,
            carbsGoal: 30,
            fatGoal: 120,
            caloriesGoal: 2000,
            waterIntake: 40,
            waterGoal: 64,
            fastingDuration: "12h 30m",
            isFasting: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        let entry = getCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        var entries: [MacroEntry] = []
        let currentDate = Date()
        
        // Update every 15 minutes
        for hourOffset in 0..<24 {
            for minuteOffset in stride(from: 0, to: 60, by: 15) {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let finalDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: entryDate)!
                entries.append(getCurrentEntry(date: finalDate))
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getCurrentEntry(date: Date = Date()) -> MacroEntry {
        // Read data from shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.com.whio.KetoMacroTracker")
        
        let protein = sharedDefaults?.double(forKey: "widget_protein") ?? 0
        let carbs = sharedDefaults?.double(forKey: "widget_carbs") ?? 0
        let fat = sharedDefaults?.double(forKey: "widget_fat") ?? 0
        let calories = sharedDefaults?.double(forKey: "widget_calories") ?? 0
        
        let proteinGoal = sharedDefaults?.double(forKey: "widget_proteinGoal") ?? 150
        let carbsGoal = sharedDefaults?.double(forKey: "widget_carbsGoal") ?? 30
        let fatGoal = sharedDefaults?.double(forKey: "widget_fatGoal") ?? 120
        let caloriesGoal = sharedDefaults?.double(forKey: "widget_caloriesGoal") ?? 2000
        
        let waterIntake = sharedDefaults?.double(forKey: "widget_waterIntake") ?? 0
        let waterGoal = sharedDefaults?.double(forKey: "widget_waterGoal") ?? 64
        
        let fastingDuration = sharedDefaults?.string(forKey: "widget_fastingDuration")
        let isFasting = sharedDefaults?.bool(forKey: "widget_isFasting") ?? false
        
        return MacroEntry(
            date: date,
            protein: protein,
            carbs: carbs,
            fat: fat,
            calories: calories,
            proteinGoal: proteinGoal,
            carbsGoal: carbsGoal,
            fatGoal: fatGoal,
            caloriesGoal: caloriesGoal,
            waterIntake: waterIntake,
            waterGoal: waterGoal,
            fastingDuration: fastingDuration,
            isFasting: isFasting
        )
    }
}

// MARK: - Widget Views
struct KetoMacroWidgetEntryView: View {
    var entry: MacroProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Net Carbs (most important for keto)
            VStack(spacing: 4) {
                Text("Net Carbs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.0f", entry.carbs))g")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(entry.carbs <= entry.carbsGoal ? .green : .red)
                
                Text("/ \(String(format: "%.0f", entry.carbsGoal))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.carbs <= entry.carbsGoal ? Color.green : Color.red)
                        .frame(width: geometry.size.width * min(entry.carbs / entry.carbsGoal, 1.0))
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Net Carbs (main focus)
            VStack(alignment: .leading, spacing: 8) {
                Text("Net Carbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.0f", entry.carbs))g")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(entry.carbs <= entry.carbsGoal ? .green : .red)
                
                Text("/ \(String(format: "%.0f", entry.carbsGoal))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Progress
                ProgressView(value: min(entry.carbs / entry.carbsGoal, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: entry.carbs <= entry.carbsGoal ? .green : .red))
            }
            
            Divider()
            
            // Right: Quick stats
            VStack(alignment: .leading, spacing: 6) {
                StatRow(label: "Protein", value: "\(String(format: "%.0f", entry.protein))g", goal: entry.proteinGoal)
                StatRow(label: "Fat", value: "\(String(format: "%.0f", entry.fat))g", goal: entry.fatGoal)
                StatRow(label: "Calories", value: "\(String(format: "%.0f", entry.calories))", goal: entry.caloriesGoal)
                
                if entry.isFasting, let duration = entry.fastingDuration {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(duration)
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: MacroEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Today's Macros")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Net Carbs (prominent)
            VStack(spacing: 4) {
                HStack {
                    Text("Net Carbs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.0f", entry.carbs))g / \(String(format: "%.0f", entry.carbsGoal))g")
                        .font(.subheadline)
                        .foregroundColor(entry.carbs <= entry.carbsGoal ? .green : .red)
                }
                
                ProgressView(value: min(entry.carbs / entry.carbsGoal, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: entry.carbs <= entry.carbsGoal ? .green : .red))
            }
            
            // All macros
            VStack(spacing: 8) {
                MacroRow(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: .blue)
                MacroRow(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: .orange)
                MacroRow(label: "Calories", value: entry.calories, goal: entry.caloriesGoal, color: .red)
            }
            
            // Water and Fasting
            HStack {
                if entry.waterIntake > 0 {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(String(format: "%.0f", entry.waterIntake))oz")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                if entry.isFasting, let duration = entry.fastingDuration {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text(duration)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views
struct StatRow: View {
    let label: String
    let value: String
    let goal: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct MacroRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.0f", value)) / \(String(format: "%.0f", goal))")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: min(value / goal, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
    }
}

// MARK: - Widget Configuration
struct KetoMacroWidget: Widget {
    let kind: String = "KetoMacroWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            KetoMacroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Keto Macros")
        .description("View your daily macro progress at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    KetoMacroWidget()
} timeline: {
    MacroEntry(
        date: Date(),
        protein: 120,
        carbs: 15,
        fat: 80,
        calories: 1800,
        proteinGoal: 150,
        carbsGoal: 30,
        fatGoal: 120,
        caloriesGoal: 2000,
        waterIntake: 40,
        waterGoal: 64,
        fastingDuration: "12h 30m",
        isFasting: true
    )
}

