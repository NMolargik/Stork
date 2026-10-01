//
//  ToastManager.swift
//  StorkDesignSystem
//
//  Lightweight top-of-screen toasts (ported from Opalite), used for background iCloud
//  sync status instead of a blocking screen. Rendering lives in `ToastView`.
//

import SwiftUI
import StorkCore

// MARK: - Toast item

public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let style: ToastStyle
    public let icon: String?
    public let duration: TimeInterval

    public init(message: String, style: ToastStyle = .info, icon: String? = nil, duration: TimeInterval = 3.0) {
        self.message = message
        self.style = style
        self.icon = icon
        self.duration = duration
    }

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast manager

@MainActor
@Observable
public final class ToastManager {
    public private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ toast: ToastItem) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = toast
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(toast.duration))
            if !Task.isCancelled { dismiss() }
        }
    }

    public func show(message: String, style: ToastStyle = .info, icon: String? = nil) {
        show(ToastItem(message: message, style: style, icon: icon))
    }

    public func showSuccess(_ message: String) {
        show(ToastItem(message: message, style: .success))
    }

    public func show(error: any LocalizedError) {
        show(ToastItem(message: error.errorDescription ?? "An error occurred", style: .error))
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = nil
        }
    }
}
