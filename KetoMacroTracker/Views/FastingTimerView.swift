//
//  FastingTimerView.swift
//  Keto Macro Tracker
//
//  View for intermittent fasting timer
//

import SwiftUI
import Combine

struct FastingTimerView: View {
    @StateObject private var fastingManager = FastingManager.shared
    @State private var selectedFastingType: FastingType = .sixteenEight
    @State private var customHours: Double = 16.0
    @State private var showingStartFasting = false
    @State private var timerTick: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if fastingManager.currentSession != nil {
                        // Active Fasting Session
                        activeFastingSection
                    } else {
                        // Start Fasting Section
                        startFastingSection
                    }
                    
                    // Stats Section
                    statsSection
                    
                    // History Section
                    if !fastingManager.fastingHistory.isEmpty {
                        historySection
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .background(AppColors.background)
            .navigationTitle("Fasting")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: timerTick) {
                // Force view update when timer ticks
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                timerTick += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Active Fasting Section
    private var activeFastingSection: some View {
        VStack(spacing: 24) {
            AppCard {
                VStack(spacing: 20) {
                    // Timer Display
                    VStack(spacing: 8) {
                        Text("Fasting Time")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text(fastingManager.getFormattedCurrentDuration())
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primary)
                            .monospacedDigit()
                        
                        if let remaining = fastingManager.getFormattedRemainingTime() {
                            Text("\(remaining) remaining")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    // Progress Ring
                    if let session = fastingManager.currentSession,
                       session.targetDuration != nil {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: fastingManager.getProgress())
                                .stroke(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(fastingManager.getProgress() * 100))%")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                        }
                    }
                    
                    // Fasting Type
                    if let session = fastingManager.currentSession {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(AppColors.primary)
                            Text(session.type.displayName)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    // End Fasting Button
                    Button(action: {
                        fastingManager.endFasting()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("End Fasting")
                                .font(AppTypography.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Start Fasting Section
    private var startFastingSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Start Fasting")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                // Fasting Type Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fasting Type")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                    
                    ForEach(FastingType.allCases.filter { $0 != .custom }, id: \.self) { type in
                        Button(action: {
                            selectedFastingType = type
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.displayName)
                                        .font(AppTypography.headline)
                                        .foregroundColor(AppColors.text)
                                    
                                    Text(type.description)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                if selectedFastingType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding()
                            .background(
                                selectedFastingType == type ?
                                AppColors.primary.opacity(0.1) :
                                AppColors.secondaryBackground
                            )
                            .cornerRadius(8)
                        }
                    }
                    
                    // Custom Option
                    Button(action: {
                        selectedFastingType = .custom
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                                
                                if selectedFastingType == .custom {
                                    Stepper("\(String(format: "%.1f", customHours)) hours", value: $customHours, in: 1...48, step: 0.5)
                                        .font(AppTypography.caption)
                                } else {
                                    Text("Set custom fasting duration")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedFastingType == .custom {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding()
                        .background(
                            selectedFastingType == .custom ?
                            AppColors.primary.opacity(0.1) :
                            AppColors.secondaryBackground
                        )
                        .cornerRadius(8)
                    }
                }
                
                // Start Button
                Button(action: {
                    let duration = selectedFastingType == .custom ?
                        customHours * 3600 :
                        selectedFastingType.defaultDuration
                    fastingManager.startFasting(type: selectedFastingType, targetDuration: duration)
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Fasting")
                            .font(AppTypography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                HStack(spacing: 20) {
                    statItem(
                        title: "Current Streak",
                        value: "\(fastingManager.getStreak())",
                        subtitle: "days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    statItem(
                        title: "7-Day Average",
                        value: formatDurationShort(fastingManager.getAverageFastingDuration(days: 7)),
                        subtitle: "per session",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
                .padding(.horizontal)
            
            ForEach(fastingManager.fastingHistory.prefix(5).sorted(by: { $0.startDate > $1.startDate })) { session in
                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.type.displayName)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                            
                            Text(formatDate(session.startDate))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(session.formattedDuration)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.primary)
                            
                            if let endDate = session.endDate {
                                Text(formatTime(endDate))
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func statItem(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
                .fontWeight(.bold)
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FastingTimerView()
}

