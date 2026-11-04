//
//  AddPhotoButton.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import PhotosUI

// A button that opens the photo library and gives back the picture the user picked.
// The look of the button is passed in, so the same code is used by the card, the gallery and the empty state.
// The picker of the system runs outside the app: no permission is needed and nothing leaves the phone.
struct AddPhotoButton<Label: View>: View {
    let onPicked: (Data) -> Void
    @ViewBuilder let label: () -> Label

    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickedItem, matching: .images) {
            label()
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    onPicked(data)
                }
                pickedItem = nil   // ready for the next photo
            }
        }
    }
}
