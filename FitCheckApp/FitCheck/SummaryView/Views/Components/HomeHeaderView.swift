//
//  HomeHeaderView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct HomeHeaderView: View {
    let name: String
    let doneThisWeek: Int
    let plannedThisWeek: Int
    let unit: CGFloat   // 1% of the screen width

    // If the user has not set a name yet, we show "User"
    private var displayName: String {
        name.isEmpty ? "User" : name
    }

    // The line under the title
    private var subtitle: String {
        if plannedThisWeek == 0 {
            // No workout plan yet: invite the user to set the first one
            return "Set your first workout plan to get started"
        }
        return "\(doneThisWeek) of \(plannedThisWeek) this week"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1 * unit) {
            Text("Hi, \(displayName)")
                .font(.system(size: 9 * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .minimumScaleFactor(0.6)   // a long name shrinks instead of wrapping
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 4.3 * unit, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)   // the invitation message can use two lines
                .fixedSize(horizontal: false, vertical: true)   // never cut the text
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    HomeHeaderView(name: "Sebastian", doneThisWeek: 1, plannedThisWeek: 3, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    HomeHeaderView(name: "Sebastian", doneThisWeek: 1, plannedThisWeek: 3, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    HomeHeaderView(name: "", doneThisWeek: 0, plannedThisWeek: 0, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
