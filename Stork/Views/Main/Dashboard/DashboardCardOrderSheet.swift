//
//  DashboardCardOrderSheet.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

struct DashboardCardOrderSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var cardOrder: [DashboardCard]
    var onSave: ([DashboardCard]) -> Void

    init(currentOrder: [DashboardCard], onSave: @escaping ([DashboardCard]) -> Void) {
        _cardOrder = State(initialValue: currentOrder)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                jarSection
                cardsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reorder Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        DashboardCard.saveOrder(cardOrder)
                        onSave(cardOrder)
                        dismiss()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .hoverEffect(.highlight)
                }
            }
        }
    }

    @ContentBuilder
    private var jarSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.title2)
                    .foregroundStyle(.storkPink)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Marble Jar")
                        .font(.body)
                    Text("Always at top")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        } header: {
            Text("Fixed Position")
        }
    }

    @ContentBuilder
    private var cardsSection: some View {
        Section {
            ForEach(cardOrder) { card in
                HStack(spacing: 12) {
                    Image(systemName: card.systemImage)
                        .font(.title2)
                        .foregroundStyle(.storkBlue)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    Text(card.displayName)
                        .font(.body)
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(card.displayName)
                .contentShape(Rectangle())
                .hoverEffect(.lift)
            }
            .onMove(perform: moveCard)
        } header: {
            Text("Drag to Reorder")
        } footer: {
            Text("Drag cards to customize your dashboard layout.")
        }
        .environment(\.editMode, .constant(.active))
    }

    private func moveCard(from source: IndexSet, to destination: Int) {
        cardOrder.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    DashboardCardOrderSheet(currentOrder: DashboardCard.defaultOrder) { _ in }
}
