//
//  RootTabView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            SummaryView()
                .tabItem { Label("Summary", systemImage: "heart.text.clipboard") }
            ProgressScreenView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}

#Preview("Light") {
    RootTabView()
        .modelContainer(rootPreviewContainer(withData: true))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RootTabView()
        .modelContainer(rootPreviewContainer(withData: true))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    RootTabView()
        .modelContainer(rootPreviewContainer(withData: false))
}
