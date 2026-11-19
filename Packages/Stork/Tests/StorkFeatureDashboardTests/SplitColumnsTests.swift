//
//  SplitColumnsTests.swift
//  StorkFeatureDashboardTests
//
//  The two-column split used by every wide layout: equal halves, or split on the hinge.
//

import Testing
import SwiftUI
import StorkDesignSystem

@Suite("SplitColumns sizing")
struct SplitColumnsTests {
    @Test("Without a fold the columns are equal halves")
    func equalHalves() {
        let w = SplitColumns<EmptyView, EmptyView>.columnWidths(total: 1000, foldCenterX: nil)
        #expect(w.leading == w.trailing)
        #expect(w.leading + w.gap + w.trailing == 1000)
    }

    @Test("With a fold the gap is centred on the hinge")
    func splitsOnHinge() {
        let w = SplitColumns<EmptyView, EmptyView>.columnWidths(total: 1100, foldCenterX: 520)
        #expect(w.leading + w.gap / 2 == 520)
        #expect(w.leading + w.gap + w.trailing == 1100)
    }

    @Test("A fold outside the container is ignored")
    func ignoresBadFold() {
        let w = SplitColumns<EmptyView, EmptyView>.columnWidths(total: 800, foldCenterX: 900)
        #expect(w.leading == w.trailing)
    }
}
