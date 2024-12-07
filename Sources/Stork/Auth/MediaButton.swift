//
//  MediaButton.swift
//
//
//  Created by Nick Molargik on 12/3/24.
//

import SkipKit
import SwiftUI

/// A button that enables the selection of media from the library or the taking of a photo.
///
/// The selected/captured image will be communicated through the `selectedImageURL` binding,
/// which can be observed with `onChange` to perform an action when the media URL is acquired.

struct MediaButton: View {
    let type: MediaPickerType // either .camera or .library
    @Binding var selectedImageURL: URL?
    @State private var showPicker = false
    var onImageSelected: ((URL?) -> Void)? // Optional callback
    
    var body: some View {
        CustomButtonView(text: (selectedImageURL == nil) ? "Select A Profile Picture" : "Change Profile Picture", width: 200, height: 40, color: Color.orange, isEnabled: .constant(true), onTapAction: {
            showPicker = true // activate the media picker
        })
        .padding()
        .accessibilityLabel(type == .camera ? "Take Photo" : "Select Media")
        .withMediaPicker(type: type, isPresented: $showPicker, selectedImageURL: $selectedImageURL)
        .onChange(of: selectedImageURL) { newValue in
            onImageSelected?(newValue)
        }
    }
}
