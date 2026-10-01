//
//  DashboardCardOrderSheet.swift
//  StorkFeatureDashboard
//
//  Drag-to-reorder the dashboard cards. The marble jar is pinned at the top. Persistence
//  is handled by the caller via `onSave`.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct DashboardCardOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cardOrder: [DashboardCard]
    let onSave: ([DashboardCard]) -> Void

    init(currentOrder: [DashboardCard], onSave: @escaping ([DashboardCard]) -> Void) {
        _cardOrder = State(initialValue: currentOrder)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                JarSection()
                CardsSection(cardOrder: $cardOrder)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Reorder Cards", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", bundle: .module)) { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save", bundle: .module)) {
                        onSave(cardOrder)
                        dismiss()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .hoverEffect(.highlight)
                }
            }
        }
    }

    private struct JarSection: View {
        var body: some View {
            Section(String(localized: "Fixed Position", bundle: .module)) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.hexagongrid.fill").font(.title2).foregroundStyle(.storkPink).frame(width: 32).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Marble Jar", bundle: .module).font(.body)
                        Text("Always at top", bundle: .module).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "lock.fill").foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private struct CardsSection: View {
        @Binding var cardOrder: [DashboardCard]

        var body: some View {
            Section {
                ForEach(cardOrder) { card in
                    HStack(spacing: 12) {
                        Image(systemName: card.systemImage).font(.title2).foregroundStyle(.storkBlue).frame(width: 32).accessibilityHidden(true)
                        Text(card.displayName).font(.body)
                        Spacer()
                        Image(systemName: "line.3.horizontal").foregroundStyle(.secondary).accessibilityHidden(true)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(card.displayName)
                    .contentShape(Rectangle())
                    .hoverEffect(.lift)
                }
                .onMove { cardOrder.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text("Drag to Reorder", bundle: .module)
            } footer: {
                Text("Drag cards to customize your dashboard layout.", bundle: .module)
            }
            .environment(\.editMode, .constant(.active))
        }
    }
}
#endif
