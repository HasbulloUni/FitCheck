//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct SummaryView: View {
    // Week data: starts empty, it only knows the current day
    @State private var weekData = WeekData()

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(spacing: 4 * unit) {
                    HomeHeaderView(name: "User", doneThisWeek: 1, plannedThisWeek: 3, unit: unit)

                    WeekCardView(days: weekData.days(), unit: unit, onEdit: {})

                    TodayCardView(
                        plan: TodayPlan(name: "Full body A", minutes: 67, exerciseCount: 11),
                        unit: unit,
                        onStart: {}
                    )
                }
                .padding(5 * unit)
            }
        }
        .background(AppColors.background)
    }
}

#Preview {
    SummaryView()
}
