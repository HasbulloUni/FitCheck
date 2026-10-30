//
//  RootTabView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            SummaryView()
                .tabItem { Label("Summary", systemImage: "heart.text.clipboard") }
            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}

#Preview {
    RootTabView()
}
