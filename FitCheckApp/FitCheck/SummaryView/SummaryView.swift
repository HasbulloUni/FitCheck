//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct SummaryView: View {
    @State private var weekData = WeekData()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HomeHeaderView(name: "User", doneThisWeek: 1, plannedThisWeek: 3)

                WeekCardView(days: weekData.days(), onEdit: {})
            }
            .padding(20)
        }
        .background(AppColors.background)
    }
}


#Preview {
    SummaryView()
}
