//
//  ToastStyle.swift
//  StorkCore
//
//  The semantic style of a transient toast. The SwiftUI background color lives in
//  `StorkDesignSystem`; Core only knows the role and its SF Symbol.
//

import Foundation

nonisolated public enum ToastStyle: Sendable {
    case error
    case success
    case info

    public var iconName: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}
