//
//  AddDeliveryToolbarButton.swift
//  Stork
//

import SwiftUI
import TipKit

/// The "+ Add" toolbar button used on every top-level screen.
struct AddDeliveryToolbarButton: View {
    let action: () -> Void
    var showsTip: Bool = false

    private let newDeliveryTip = NewDeliveryTip()

    var body: some View {
        if showsTip {
            button
                .popoverTip(newDeliveryTip, arrowEdge: .top)
                .tipViewStyle(StorkTipViewStyle())
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            Label("Add", systemImage: "plus")
                .imageScale(.large)
                .bold()
        }
        .tint(.storkBlue)
        .labelStyle(.titleAndIcon)
        .accessibilityIdentifier("addEntryButton")
        .keyboardShortcut("n", modifiers: .command)
        .hoverEffect(.highlight)
    }
}

#Preview {
    NavigationStack {
        Text("Content")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    AddDeliveryToolbarButton(action: {})
                }
            }
    }
}
