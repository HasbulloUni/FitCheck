//
//  HomeHeaderView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct HomeHeaderView: View {
    let name: String
    let plannedThisWeek: Int
    let unit: CGFloat   // 1% of the screen width
    var onInfo: (() -> Void)? = nil   // the info button (nil = not shown)

    // If the user has not set a name yet, we show "User"
    private var displayName: String {
        name.isEmpty ? "User" : name
    }

    // The line under the title: only the invitation when there is no workout plan yet.
    // The progress of the week is already in the "This week" card, so it is not repeated here.
    private var subtitle: String? {
        plannedThisWeek == 0 ? "Set your first workout plan to get started" : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
            HStack {
                Text("Hi, \(displayName)")
                    .font(.system(size: AppSizes.Text.hero * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.6)   // a long name shrinks instead of wrapping
                    .lineLimit(1)

                if let onInfo {
                    Spacer()
                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .font(.system(size: AppSizes.Text.bodyLarge * unit * 1.3))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .accessibilityLabel("Info")
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)   // the invitation message can use two lines
                    .fixedSize(horizontal: false, vertical: true)   // never cut the text
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    HomeHeaderView(name: "Sebastian", plannedThisWeek: 3, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    HomeHeaderView(name: "Sebastian", plannedThisWeek: 3, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    HomeHeaderView(name: "", plannedThisWeek: 0, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
