//
//  TagPickerSheet.swift
//  StorkFeatureDeliveries
//
//  Select, create, and preview tags for a delivery. Reads and writes tags through the
//  entry model's tag use-cases — never the model context directly.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: DeliveryEntryModel

    @State private var newTagName = ""
    @State private var selectedColorHex = "007AFF"

    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "007AFF"), ("Orange", "FF9500"), ("Red", "FF3B30"),
        ("Green", "34C759"), ("Purple", "AF52DE"), ("Pink", "FF2D55"),
        ("Indigo", "5856D6"), ("Teal", "00C7BE"), ("Yellow", "FFCC00"), ("Cyan", "30B0C7"),
    ]

    var body: some View {
        NavigationStack {
            List {
                if model.availableTags.isEmpty {
                    Section("Suggested Tags") {
                        ForEach(DeliveryTag.presets, id: \.name) { preset in
                            Button {
                                model.createAndSelectTag(name: preset.name, colorHex: preset.colorHex)
                            } label: {
                                HStack {
                                    Circle().fill(Color(hex: preset.colorHex) ?? .blue).frame(width: 12, height: 12)
                                    Text(preset.name).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle").foregroundStyle(.storkPurple)
                                }
                            }
                        }
                    }
                } else {
                    Section("Your Tags") {
                        ForEach(model.availableTags) { tag in
                            Button {
                                model.toggleTag(tag)
                            } label: {
                                HStack {
                                    Circle().fill(tag.color).frame(width: 12, height: 12)
                                    Text(tag.name).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: model.selectedTags.contains(where: { $0.id == tag.id }) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(model.selectedTags.contains(where: { $0.id == tag.id }) ? .storkPurple : .secondary)
                                }
                            }
                        }
                    }
                }

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
                                        .overlay(Circle().strokeBorder(.white, lineWidth: selectedColorHex == option.hex ? 3 : 0))
                                        .shadow(color: selectedColorHex == option.hex ? .black.opacity(0.3) : .clear, radius: 2)
                                }
                                .accessibilityLabel(option.name)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        model.createAndSelectTag(name: newTagName, colorHex: selectedColorHex)
                        newTagName = ""
                    } label: {
                        Label("Create Tag", systemImage: "plus.circle.fill")
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .tint(.storkPurple)
                }

                if !model.selectedTags.isEmpty {
                    Section("Selected (\(model.selectedTags.count))") {
                        FlowLayout(spacing: 8) {
                            ForEach(model.selectedTags) { tag in
                                TagChipView(tag: tag) { model.removeTag(id: tag.id) }
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
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { model.loadTags() }
        }
    }
}
#endif
