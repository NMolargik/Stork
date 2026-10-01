//
//  AddDeliveryToolbarButton.swift
//  StorkFeatureDeliveries
//
//  The one prominent "+ Add" toolbar button used on top-level screens, plus the
//  first-run TipKit hint that points at it.
//

#if os(iOS)
import SwiftUI
import TipKit
import StorkDesignSystem

/// First-run tip guiding the user to record their first delivery.
public struct NewDeliveryTip: Tip {
    public init() {}
    public var title: Text { Text("Record a Delivery", bundle: .module) }
    public var message: Text? { Text("Tap here to start tracking your first delivery.", bundle: .module) }
    public var image: Image? { Image(systemName: "plus.circle.fill") }
}

/// Tints the tip icon with the brand blue.
struct StorkTipViewStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.image?
                .foregroundStyle(.storkBlue)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                configuration.title.font(.headline)
                configuration.message?
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

public struct AddDeliveryToolbarButton: View {
    private let action: () -> Void
    private let showsTip: Bool
    private let newDeliveryTip = NewDeliveryTip()

    public init(action: @escaping () -> Void, showsTip: Bool = false) {
        self.action = action
        self.showsTip = showsTip
    }

    public var body: some View {
        if showsTip {
            ProminentAddButton(action: action)
                .popoverTip(newDeliveryTip, arrowEdge: .top)
                .tipViewStyle(StorkTipViewStyle())
        } else {
            ProminentAddButton(action: action)
        }
    }

    private struct ProminentAddButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label(String(localized: "Add", bundle: .module), systemImage: "plus")
                    .imageScale(.large)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .tint(.storkBlue)
            .labelStyle(.titleAndIcon)
            .accessibilityIdentifier("addEntryButton")
            .keyboardShortcut("n", modifiers: .command)
            .hoverEffect(.highlight)
        }
    }
}
#endif
