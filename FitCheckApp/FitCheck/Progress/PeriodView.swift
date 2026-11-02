//
//  PeriodView.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct Box: View {
    let text: String

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(20)
    }
}

struct TopCards: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                NavigationLink(destination: SessionsDetailView()) {
                    Box(text: "Sessions")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: MinutesView()) {
                    Box(text: "Minutes")
                }
                .buttonStyle(.plain)
            }

            NavigationLink(destination: PhotosView()) {
                Box(text: "Photos")
            }
            .buttonStyle(.plain)
        }
    }
}

struct DayView: View {
    var body: some View {
        VStack(spacing: 12) {
            TopCards()
            Box(text: "Today's session")
        }
    }
}

struct WeekView: View {
    var body: some View {
        VStack(spacing: 12) {
            TopCards()
            Box(text: "Minutes per day")
        }
    }
}

struct MonthView: View {
    var body: some View {
        VStack(spacing: 12) {
            TopCards()
            Box(text: "Minutes per week")
        }
    }
}
