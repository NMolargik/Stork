//
//  ReviewRequesting.swift
//  Stork
//

#if !os(watchOS)
import StoreKit
import UIKit

/// Seam over StoreKit's review prompt so prompting rules can be tested.
@MainActor
protocol ReviewRequesting {
    func requestReview(in scene: UIWindowScene)
}

struct AppStoreReviewRequester: ReviewRequesting {
    nonisolated init() {}

    func requestReview(in scene: UIWindowScene) {
        AppStore.requestReview(in: scene)
    }
}
#endif
