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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hi, \(name)")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("\(doneThisWeek) of \(plannedThisWeek) this week")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeHeaderView(name: "Sebastian", doneThisWeek: 1, plannedThisWeek: 3)
        .padding(20)
        .background(AppColors.background)
}
