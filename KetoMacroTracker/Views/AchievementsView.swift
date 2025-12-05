//
//  AchievementsView.swift
//  Keto Macro Tracker
//
//  View for displaying achievements and badges
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Header
                    statsHeader
                    
                    // Unlocked Achievements
                    if !achievementManager.unlockedAchievements.isEmpty {
                        unlockedSection
                    }
                    
                    // All Achievements
                    allAchievementsSection
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .background(AppColors.background)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Header
    private var statsHeader: some View {
        AppCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(achievementManager.unlockedAchievements.count)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        
                        Text("Achievements Unlocked")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                }
                
                Text("Keep logging to unlock more achievements!")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
    
    // MARK: - Unlocked Section
    private var unlockedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlocked")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(achievementManager.unlockedAchievements.sorted(by: { $0.unlockedDate > $1.unlockedDate })) { achievement in
                    AchievementBadge(achievement: achievement, isUnlocked: true)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - All Achievements Section
    private var allAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Achievements")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(AchievementType.allCases, id: \.self) { type in
                    let isUnlocked = achievementManager.isUnlocked(type)
                    let progress = achievementManager.getAchievementProgress(for: type)
                    
                    if isUnlocked {
                        if let achievement = achievementManager.unlockedAchievements.first(where: { $0.type == type }) {
                            AchievementBadge(achievement: achievement, isUnlocked: true)
                        }
                    } else {
                        AchievementBadge(
                            achievement: Achievement(type: type, progress: progress),
                            isUnlocked: false
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(
                            colors: [achievement.type.color, achievement.type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.type.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            VStack(spacing: 4) {
                Text(achievement.type.title)
                    .font(AppTypography.headline)
                    .foregroundColor(isUnlocked ? AppColors.text : AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Text(achievement.type.description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !isUnlocked && achievement.progress > 0 {
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.type.color))
                        .frame(height: 4)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isUnlocked ? achievement.type.color.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? achievement.type.color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    AchievementsView()
}

