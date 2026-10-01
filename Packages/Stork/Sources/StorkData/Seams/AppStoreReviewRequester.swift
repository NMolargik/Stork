//
//  AppStoreReviewRequester.swift
//  StorkData
//
//  The production `ReviewRequesting` conformance. Resolves the active foreground window
//  scene itself, so callers don't plumb UIKit through the domain.
//

import StorkCore
#if os(iOS)
import StoreKit
import UIKit
#endif

public struct AppStoreReviewRequester: ReviewRequesting {
    public init() {}

    public func requestReview() {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        AppStore.requestReview(in: scene)
        #endif
    }
}
