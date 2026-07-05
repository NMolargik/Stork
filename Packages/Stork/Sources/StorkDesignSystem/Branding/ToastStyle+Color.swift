//
//  ToastStyle+Color.swift
//  StorkDesignSystem
//
//  The background color for each toast role. The role + icon live in Core; the color
//  lives here with the rest of the palette.
//

import SwiftUI
import StorkCore

public extension ToastStyle {
    var backgroundColor: Color {
        switch self {
        case .error: .red
        case .success: .green
        case .info: .storkBlue
        }
    }
}
