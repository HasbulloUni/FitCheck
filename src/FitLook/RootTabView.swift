//
//  RootTabView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    // The two tabs
    private enum AppTab {
        case summary
        case progress
    }

    @State private var selectedTab: AppTab = .summary

    // Goes up by one each time the Progress tab is tapped while it is already open:
    // the Progress screen then closes Photos, Compare and the viewer
    @State private var progressRootTrigger = 0

    var body: some View {
        // This binding also hears a tap on the tab that is already selected
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab && newTab == .progress {
                    progressRootTrigger += 1
                }
                selectedTab = newTab
            }
        )) {
            SummaryView()
                .tabItem { Label("Summary", systemImage: "heart.text.clipboard") }
                .tag(AppTab.summary)
            ProgressScreenView(popToRootTrigger: progressRootTrigger)
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)
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
