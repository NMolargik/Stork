//
//  WideLayout.swift
//  StorkDesignSystem
//
//  Two-column layouts for wide screens: the unfolded iPhone Duo (one wide screen with a
//  hinge down the middle) and iPad in regular width. Folded, the Duo is an iPhone and keeps
//  the single-column layouts.
//

import SwiftUI

public extension LayoutProbe {
    /// Narrowest container (points) that gets two columns.
    static let twoColumnMinimumWidth: CGFloat = 640

    /// Whether a screen should split into two columns: regular width (iPad, unfolded Duo) or
    /// a fold dividing the window, and wide enough for two usable columns. iPhone in landscape
    /// is wide but compact, so it keeps the single column.
    func usesTwoColumns(isRegularWidth: Bool) -> Bool {
        width >= Self.twoColumnMinimumWidth && (isRegularWidth || hasFold)
    }
}

/// Two equal columns either side of the hinge. With a vertical fold dividing the container the
/// split lands exactly on it (and the gap widens so nothing sits in the curve); without one the
/// columns are equal halves. Each column is given the full height, so each can scroll on its own.
public struct SplitColumns<Leading: View, Trailing: View>: View {
    private let leading: Leading
    private let trailing: Trailing

    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        GeometryReader { proxy in
            let widths = Self.columnWidths(total: proxy.size.width, foldCenterX: proxy.foldCenterXIfAvailable)
            HStack(spacing: 0) {
                leading.frame(width: widths.leading, height: proxy.size.height)
                Color.clear.frame(width: widths.gap, height: 1)
                trailing.frame(width: widths.trailing, height: proxy.size.height)
            }
        }
    }

    /// Pure sizing, exposed for tests.
    nonisolated public static func columnWidths(total: CGFloat, foldCenterX: CGFloat?) -> (leading: CGFloat, gap: CGFloat, trailing: CGFloat) {
        if let fold = foldCenterX, fold > 0, fold < total {
            let gap: CGFloat = 48
            return (max(fold - gap / 2, 0), gap, max(total - fold - gap / 2, 0))
        }
        let gap: CGFloat = 24
        let column = max((total - gap) / 2, 0)
        return (column, gap, column)
    }
}

// MARK: - Hinge-safe centering

public extension View {
    /// Centres a single column of content (a story page, a celebration card) so nothing crosses a
    /// vertical hardware fold: with a fold dividing the container, the content is centred in the
    /// leading half; everywhere else it is centred in the whole container, as before.
    func centeredAwayFromHinge() -> some View {
        modifier(HingeSafeCentering())
    }
}

private struct HingeSafeCentering: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let widths = SplitColumns<EmptyView, EmptyView>.columnWidths(total: proxy.size.width, foldCenterX: proxy.foldCenterXIfAvailable)
            let hasFold = proxy.foldCenterXIfAvailable != nil
            content
                .frame(width: hasFold ? widths.leading : proxy.size.width, height: proxy.size.height)
        }
    }
}
