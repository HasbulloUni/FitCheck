//
//  PhotosView.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct PhotosView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.system(size: 34, weight: .heavy, design: .rounded))

            NavigationLink(destination: PlaceholderView(title: "Add photo")) {
                Box(text: "Add photo")
            }
            .buttonStyle(.plain)

            NavigationLink(destination: PlaceholderView(title: "Compare photos")) {
                Box(text: "Compare photos")
            }
            .buttonStyle(.plain)

            NavigationLink(destination: PlaceholderView(title: "Photo detail")) {
                Box(text: "Photo detail")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(20)
    }
}
