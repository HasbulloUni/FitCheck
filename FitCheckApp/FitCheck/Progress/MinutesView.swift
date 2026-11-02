//
//  MinutesView.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct MinutesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minutes")
                .font(.system(size: 34, weight: .heavy, design: .rounded))

            NavigationLink(destination: PlaceholderView(title: "Weeks active")) {
                Box(text: "Weeks active")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
    }
}
