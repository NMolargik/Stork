//
//  ShareSheet.swift
//  StorkDesignSystem
//
//  `UIActivityViewController` wrapper with a completion so callers learn whether the user
//  actually shared (the review prompt after the first milestone-card share hangs off this).
//

#if os(iOS)
import SwiftUI
import UIKit

public struct ShareSheet: UIViewControllerRepresentable {
    private let items: [Any]
    private let onComplete: ((Bool) -> Void)?

    /// - Parameters:
    ///   - items: Activity items (images, URLs, text).
    ///   - onComplete: Called once with `true` when an activity completed, `false` on cancel.
    public init(items: [Any], onComplete: ((Bool) -> Void)? = nil) {
        self.items = items
        self.onComplete = onComplete
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        let onComplete = self.onComplete
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// An image with identity, for `.sheet(item:)` presentation of a rendered card.
public struct IdentifiableImage: Identifiable {
    public let id = UUID()
    public let image: UIImage

    public init(image: UIImage) {
        self.image = image
    }
}
#endif
