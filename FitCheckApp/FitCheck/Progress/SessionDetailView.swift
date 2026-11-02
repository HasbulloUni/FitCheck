//
//  SessionDetailView.swift
//  FitCheck
//
//  Created by AFP FED 004 on 02/11/2026.
//

import SwiftUI

struct SessionsDetailView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sessions")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
