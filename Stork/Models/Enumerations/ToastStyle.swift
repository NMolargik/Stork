//
//  ToastStyle.swift
//  Stork
//

import SwiftUI

enum ToastStyle {
    case error
    case success
    case info

    var backgroundColor: Color {
        switch self {
        case .error: .red
        case .success: .green
        case .info: .storkBlue
        }
    }

    var iconName: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}
