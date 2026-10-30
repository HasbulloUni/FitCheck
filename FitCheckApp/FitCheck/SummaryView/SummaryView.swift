//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct SummaryView: View {
    var body: some View {
        ZStack {
            HomeHeaderView(name:"User", doneThisWeek: 1, plannedThisWeek: 3).padding(20).background(AppColors.background)
        }
    }
}

#Preview {
    SummaryView()
}
