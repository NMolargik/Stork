//
//  TagViews.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

// MARK: - Tag Chip View

struct TagChipView: View {
    let tag: DeliveryTag
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tag.color.opacity(0.15), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(tag.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tag: \(tag.name)")
        .accessibilityHint(onRemove != nil ? "Double tap to remove" : "")
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions, sizes)
    }
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DeliveryTag.name) private var allTags: [DeliveryTag]

    @Binding var selectedTags: [DeliveryTag]
    @State private var newTagName: String = ""
    @State private var selectedColorHex: String = "007AFF"
    @State private var showingNewTagSection = false

    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "007AFF"),
        ("Orange", "FF9500"),
        ("Red", "FF3B30"),
        ("Green", "34C759"),
        ("Purple", "AF52DE"),
        ("Pink", "FF2D55"),
        ("Indigo", "5856D6"),
        ("Teal", "00C7BE"),
        ("Yellow", "FFCC00"),
        ("Cyan", "30B0C7")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Preset suggestions section (only show if no tags exist)
                if allTags.isEmpty {
                    Section("Suggested Tags") {
                        ForEach(DeliveryTag.presets, id: \.name) { preset in
                            Button {
                                createAndSelectTag(name: preset.name, colorHex: preset.colorHex)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: preset.colorHex) ?? .blue)
                                        .frame(width: 12, height: 12)
                                    Text(preset.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.storkPurple)
                                }
                            }
                        }
                    }
                }

                // Existing tags section
                if !allTags.isEmpty {
                    Section("Your Tags") {
                        ForEach(allTags) { tag in
                            Button {
                                toggleTag(tag)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(tag.color)
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedTags.contains(where: { $0.id == tag.id }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.storkPurple)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }
                }

                // Create new tag section
                Section("Create New Tag") {
                    TextField("Tag name", text: $newTagName)
                        .textInputAutocapitalization(.words)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.hex) { option in
                                Button {
                                    selectedColorHex = option.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: option.hex) ?? .blue)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.white, lineWidth: selectedColorHex == option.hex ? 3 : 0)
                                        )
                                        .shadow(color: selectedColorHex == option.hex ? .black.opacity(0.3) : .clear, radius: 2)
                                }
                                .accessibilityLabel(option.name)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        createAndSelectTag(name: newTagName, colorHex: selectedColorHex)
                        newTagName = ""
                    } label: {
                        Label("Create Tag", systemImage: "plus.circle.fill")
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .tint(.storkPurple)
                }

                // Selected tags preview
                if !selectedTags.isEmpty {
                    Section("Selected (\(selectedTags.count))") {
                        FlowLayout(spacing: 8) {
                            ForEach(selectedTags) { tag in
                                TagChipView(tag: tag) {
                                    if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                        selectedTags.remove(at: index)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleTag(_ tag: DeliveryTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func createAndSelectTag(name: String, colorHex: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Check if tag already exists
        if let existing = allTags.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            if !selectedTags.contains(where: { $0.id == existing.id }) {
                selectedTags.append(existing)
            }
            return
        }

        let newTag = DeliveryTag(name: trimmedName, colorHex: colorHex)
        modelContext.insert(newTag)
        selectedTags.append(newTag)
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = allTags[index]
            // Remove from selected if present
            selectedTags.removeAll { $0.id == tag.id }
            modelContext.delete(tag)
        }
    }
}

#Preview("Tag Chip") {
    TagChipView(tag: DeliveryTag.sample) {
        print("Remove tapped")
    }
    .padding()
}

#Preview("Tag Picker") {
    TagPickerSheet(selectedTags: .constant([]))
}
