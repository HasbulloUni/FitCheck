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

    var body: some View {
        VStack(alignment: .leading, spacing: 1 * unit) {
            Text("Hi, \(name)")
                .font(.system(size: 9 * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .minimumScaleFactor(0.6)   // a long name shrinks instead of wrapping
                .lineLimit(1)

            Text("\(doneThisWeek) of \(plannedThisWeek) this week")
                .font(.system(size: 4.3 * unit, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
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
