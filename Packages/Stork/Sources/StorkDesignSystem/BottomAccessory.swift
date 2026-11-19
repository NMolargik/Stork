//
//  BottomAccessory.swift
//  StorkDesignSystem
//
//  How much of the bottom of the content area the floating step pill covers, so scrolling
//  content can leave room for it (the system does not inset tab content for it everywhere).
//

import SwiftUI

private struct BottomAccessoryClearanceKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    /// Height (points) of the bottom accessory floating over the content while it is shown; 0 when there is none.
    var bottomAccessoryClearance: CGFloat {
        get { self[BottomAccessoryClearanceKey.self] }
        set { self[BottomAccessoryClearanceKey.self] = newValue }
    }
}
