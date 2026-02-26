//
//  DesignSystem.swift
//  KetoMacroTracker
//
//  Created by Oz Hardoon on 9/27/25.
//

import SwiftUI

// MARK: - Color System
struct AppColors {
    // Primary Colors
    static let primary = Color(red: 0.2, green: 0.7, blue: 0.4) // Keto Green
    static let primaryLight = Color(red: 0.3, green: 0.8, blue: 0.5)
    static let primaryDark = Color(red: 0.1, green: 0.6, blue: 0.3)
    
    // Accent Colors
    static let accent = Color(red: 0.9, green: 0.6, blue: 0.2) // Orange accent
    static let accentLight = Color(red: 0.95, green: 0.7, blue: 0.3)
    
    // Macro Colors
    static let protein = Color(red: 0.9, green: 0.3, blue: 0.3) // Red for protein
    static let carbs = Color(red: 0.2, green: 0.5, blue: 0.9) // Blue for carbs
    static let fat = Color(red: 0.9, green: 0.7, blue: 0.2) // Yellow for fat
    static let calories = Color(red: 0.6, green: 0.3, blue: 0.8) // Purple for calories
    static let cholesterol = Color(red: 0.85, green: 0.4, blue: 0.3) // Red-orange for cholesterol
    static let saturatedFat = Color(red: 0.8, green: 0.5, blue: 0.2) // Dark orange for saturated fat
    
    // Neutral Colors
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let border = Color(UIColor.separator)
    
    // Status Colors
    static let success = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.2)
    static let error = Color(red: 0.9, green: 0.3, blue: 0.3)
}

// MARK: - Typography
struct AppTypography {
    // Headers
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body Text
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // Numbers and Metrics
    static let largeNumber = Font.system(size: 48, weight: .bold, design: .rounded)
    static let mediumNumber = Font.system(size: 32, weight: .bold, design: .rounded)
    static let smallNumber = Font.system(size: 20, weight: .semibold, design: .rounded)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
}

// MARK: - Shadows
struct AppShadows {
    static let small = Color.black.opacity(0.1)
    static let medium = Color.black.opacity(0.15)
    static let large = Color.black.opacity(0.2)
}

// MARK: - Reusable UI Components
struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(color: AppShadows.small, radius: 2, x: 0, y: 1)
    }
}

struct AppButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }
    
    init(action: @escaping () -> Void, style: ButtonStyle = .primary, @ViewBuilder content: () -> Content) {
        self.action = action
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .font(AppTypography.headline)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(AppColors.primary, lineWidth: style == .outline ? 2 : 0)
                )
                .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return AppColors.primary
        case .secondary: return AppColors.secondaryBackground
        case .outline: return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return AppColors.text
        case .outline: return AppColors.primary
        }
    }
}

// MARK: - Macro Progress Bar
struct MacroProgressBar: View {
    let title: String
    let current: Double
    let goal: Double
    let color: Color
    let unit: String
    
    var progress: Double {
        min(current / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("\(Int(current))/\(Int(goal)) \(unit)")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

// MARK: - Macro Circle
struct MacroCircle: View {
    let title: String
    let current: Double
    let goal: Double
    let color: Color
    let unit: String
    
    var progress: Double {
        min(current / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(current))")
                        .font(AppTypography.largeNumber)
                        .foregroundColor(color)
                        .fontWeight(.bold)
                    
                    Text(unit)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .frame(width: 120, height: 120)
            
            Text(title)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.text)
                .fontWeight(.medium)
        }
    }
}


