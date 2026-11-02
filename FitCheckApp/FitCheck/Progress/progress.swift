//
//  progress.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct ProgressScreen: View {
    @State private var selected = "Week"

    let exploreItems = ["Muscle", "Day and time", "Plan", "Feelings", "Loads", "Reached"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                Text("Progress")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))

                Picker("Periodo", selection: $selected) {
                    Text("Day").tag("Day")
                    Text("Week").tag("Week")
                    Text("Month").tag("Month")
                }
                .pickerStyle(.segmented)

                if selected == "Day" {
                    DayView()
                } else if selected == "Week" {
                    WeekView()
                } else {
                    MonthView()
                }

                Text("Explore")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(exploreItems, id: \.self) { name in
                        NavigationLink(destination: destinationView(for: name)) {
                            Box(text: name)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(20)
        }
    }

    @ViewBuilder
    func destinationView(for name: String) -> some View {
        if name == "Reached" {
            ReachedView()
        } else {
            PlaceholderView(title: name)
        }
    }
}

#Preview {
    ProgressScreen()
}
