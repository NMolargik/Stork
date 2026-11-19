//
//  StatusCenter.swift
//  StorkDesignSystem
//
//  Quiet, inline status feedback, as in Opalite and Mygra. A transient status (saved, imported,
//  added) is shown in the screen's navigation subtitle for a few seconds and then clears.
//  Nothing floats over content. Real failures are not routed here: they use an alert with the
//  error. Pro limits go straight to the paywall (`requestProUpgrade`).
//

import SwiftUI

@MainActor
@Observable
public final class StatusCenter {
    /// The status shown in navigation subtitles, or nil when there is none.
    public private(set) var message: String?
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    public init() {}

    /// Shows an already-localized status line for `duration` seconds.
    public func show(_ message: String, duration: TimeInterval = 3.0) {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) { self.message = message }
        // A subtitle change is not announced on its own.
        AccessibilityNotification.Announcement(message).post()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            if !Task.isCancelled { self?.dismiss() }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) { message = nil }
    }
}

#if os(iOS)
private struct StatusSubtitleModifier: ViewModifier {
    let subtitle: String
    @Environment(StatusCenter.self) private var status: StatusCenter?

    func body(content: Content) -> some View {
        content.navigationSubtitle(Text(verbatim: status?.message ?? subtitle))
    }
}

public extension View {
    /// The current status in this screen's navigation subtitle; `subtitle` shows when there is none.
    func statusSubtitle(replacing subtitle: String = "") -> some View {
        modifier(StatusSubtitleModifier(subtitle: subtitle))
    }
}
#endif
