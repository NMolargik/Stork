//
//  FoldSplitLayout.swift
//  StorkDesignSystem
//

import SwiftUI

/// Three fixed regions side by side: leading pane, separator, trailing pane. The layout always
/// reports exactly the size it is proposed and gives each child an exact frame, so what the
/// panes contain can never change the container's own size (which the adaptive layout measures:
/// a flexible stack let the panes' content nudge the width by fractions of a point, which moved
/// the pane widths, which moved the content, without end).
public struct FoldSplitLayout: Layout {
    /// Width of the leading pane (integral, from the container's width or the fold).
    public var leadingWidth: CGFloat
    /// Width of the separator between the panes (the hinge gap, or a hairline).
    public var separatorWidth: CGFloat

    public init(leadingWidth: CGFloat, separatorWidth: CGFloat) {
        self.leadingWidth = leadingWidth
        self.separatorWidth = separatorWidth
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 800, height: proposal.height ?? 600)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let leading = min(leadingWidth.rounded(), bounds.width)
        let separator = min(separatorWidth, max(bounds.width - leading, 0))
        let trailing = max(bounds.width - leading - separator, 0)
        let frames = [
            CGRect(x: bounds.minX, y: bounds.minY, width: leading, height: bounds.height),
            CGRect(x: bounds.minX + leading, y: bounds.minY, width: separator, height: bounds.height),
            CGRect(x: bounds.minX + leading + separator, y: bounds.minY, width: trailing, height: bounds.height)
        ]
        for (subview, frame) in zip(subviews, frames) {
            subview.place(at: frame.origin, anchor: .topLeading, proposal: ProposedViewSize(width: frame.width, height: frame.height))
        }
    }
}
