//
//  ReviewRequesting.swift
//  StorkCore
//
//  Seam over StoreKit's review prompt so prompting rules can be tested. The protocol is
//  UIKit-free (the concrete requester in `StorkData` resolves the active scene itself).
//

import Foundation

@MainActor
public protocol ReviewRequesting {
    /// Asks the system to consider showing a review prompt.
    func requestReview()
}
