//
//  ReachedView.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct ReachedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reached")
                .font(.system(size: 34, weight: .heavy, design: .rounded))

            NavigationLink(destination: PlaceholderView(title: "Goal reached")) {
                Box(text: "Goal reached")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
    }
}
