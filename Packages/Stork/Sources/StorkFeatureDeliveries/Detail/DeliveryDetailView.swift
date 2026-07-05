//
//  DeliveryDetailView.swift
//  StorkFeatureDeliveries
//
//  Full delivery detail: a sex-tinted hero header, quick-stat pills, per-baby cards, tags,
//  and notes. Editing reuses the entry form (`DeliveryEntryView` in edit mode); delete and
//  reload are reported through closures the embedding screen wires to the use-cases.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct DeliveryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let delivery: Delivery
    private let onDelete: () -> Void
    private let makeEditModel: () -> DeliveryEntryModel
    private let onEdited: () -> Void

    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    public init(
        delivery: Delivery,
        onDelete: @escaping () -> Void,
        makeEditModel: @escaping () -> DeliveryEntryModel,
        onEdited: @escaping () -> Void = {}
    ) {
        self.delivery = delivery
        self.onDelete = onDelete
        self.makeEditModel = makeEditModel
        self.onEdited = onEdited
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeroHeader(delivery: delivery)
                ContentSection(delivery: delivery)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSheet = true } label: { Label("Edit", systemImage: "pencil") }
                    .hoverEffect(.highlight)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Delete", systemImage: "trash") }
            }
        }
        .confirmationDialog("Delete this delivery?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                dismiss()
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            DeliveryEntryView(model: makeEditModel()) { _ in onEdited() }
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Hero header

    private struct HeroHeader: View {
        let delivery: Delivery

        private var babies: [Baby] { delivery.babies ?? [] }

        private var gradientColors: [Color] {
            let male = babies.count { $0.sex == .male }
            let female = babies.count { $0.sex == .female }
            let loss = babies.count { $0.sex == .loss }
            var colors = Array(repeating: Color.storkBlue, count: male)
                + Array(repeating: Color.storkPink, count: female)
                + Array(repeating: Color.storkPurple, count: loss)
            if colors.count == 1, let only = colors.first {
                colors = [only, only.opacity(0.8)]
            } else if colors.isEmpty {
                colors = [.gray.opacity(0.7), .gray.opacity(0.5)]
            }
            return colors
        }

        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(Rectangle().fill(.white.opacity(0.15)))

                    VStack(spacing: 8) {
                        Text(delivery.date.formatted(.dateTime.hour().minute()) + " - " + delivery.date.formatted(.dateTime.weekday(.wide)))
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                        Text(delivery.date.formatted(.dateTime.month(.wide).day()))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(delivery.date.formatted(.dateTime.year()))
                            .font(.title3).fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.vertical, 32)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Delivery date")
                    .accessibilityValue(delivery.date.formatted(date: .complete, time: .shortened))
                }
                .frame(maxWidth: .infinity)

                QuickStatsRow(delivery: delivery)
                    .frame(maxWidth: 700)
                    .padding(.horizontal, 16)
                    .offset(y: -24)
            }
        }
    }

    private struct QuickStatsRow: View {
        let delivery: Delivery

        private var babies: [Baby] { delivery.babies ?? [] }

        var body: some View {
            HStack(spacing: 12) {
                StatPill(icon: "figure.and.child.holdinghands", value: "\(babies.count)",
                         label: babies.count == 1 ? String(localized: "Baby") : String(localized: "Babies"), color: .storkBlue)
                StatPill(icon: delivery.deliveryMethod.detailIcon, value: delivery.deliveryMethod.description,
                         label: "Method", color: delivery.deliveryMethod.accentColor)
                StatPill(icon: "syringe.fill", value: delivery.epiduralUsed ? "Yes" : "No",
                         label: "Epidural", color: delivery.epiduralUsed ? .red : .secondary)
            }
        }
    }

    private struct StatPill: View {
        let icon: String
        let value: String
        let label: String
        let color: Color

        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3).foregroundStyle(color).frame(height: 30)
                Text(value).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.8)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: 85)
            .statPillBackground()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value)
        }
    }

    // MARK: - Content

    private struct ContentSection: View {
        let delivery: Delivery

        private var babies: [Baby] { delivery.babies ?? [] }

        var body: some View {
            VStack(spacing: 20) {
                if !babies.isEmpty { BabiesSection(babies: babies) }
                if let tags = delivery.tags, !tags.isEmpty { TagsSection(tags: tags) }
                if let notes = delivery.notes, !notes.isEmpty { NotesSection(notes: notes) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private struct BabiesSection: View {
        let babies: [Baby]

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Babies", icon: "heart.fill", color: .pink)
                ForEach(Array(babies.enumerated()), id: \.element.id) { index, baby in
                    BabyCard(baby: baby, index: index + 1)
                }
            }
        }
    }

    private struct BabyCard: View {
        let baby: Baby
        let index: Int

        @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Circle().fill(baby.sex.color).frame(width: 12, height: 12)
                        Text("Baby \(index)").font(.subheadline).fontWeight(.semibold)
                        Text("(\(baby.sex.displayName))").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(baby.birthday.formatted(.dateTime.hour().minute())).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(baby.sex.color.opacity(0.1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Baby \(index), \(baby.sex.displayName), born at \(baby.birthday.formatted(.dateTime.hour().minute()))")

                HStack(spacing: 0) {
                    Measurement(icon: "scalemass.fill", color: .storkOrange,
                                value: UnitConversion.weightDisplay(baby.weight, useMetric: useMetricUnits), label: "Weight")
                    Divider().frame(height: 50)
                    Measurement(icon: "ruler", color: .green,
                                value: UnitConversion.heightDisplay(baby.height, useMetric: useMetricUnits), label: "Length")
                }

                if baby.nurseCatch || baby.nicuStay {
                    Divider()
                    HStack(spacing: 12) {
                        if baby.nurseCatch {
                            Label("Nurse Catch", systemImage: "stethoscope")
                                .font(.caption).fontWeight(.medium).foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(.red.gradient, in: Capsule())
                        }
                        if baby.nicuStay {
                            Label("NICU Stay", systemImage: "bed.double.fill")
                                .font(.caption).fontWeight(.medium).foregroundStyle(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(.orange.gradient, in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private struct Measurement: View {
        let icon: String
        let color: Color
        let value: String
        let label: String

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(value).font(.headline).fontWeight(.bold)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value)
        }
    }

    private struct TagsSection: View {
        let tags: [DeliveryTag]

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Tags", icon: "tag.fill", color: .storkPurple)
                FlowLayout(spacing: 8) {
                    ForEach(tags) { tag in TagChipView(tag: tag) }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private struct NotesSection: View {
        let notes: String

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Notes", icon: "note.text", color: .storkOrange)
                Text(notes)
                    .font(.body).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private struct SectionHeader: View {
        let title: String
        let icon: String
        let color: Color

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(color).accessibilityHidden(true)
                Text(title).font(.headline).fontWeight(.bold)
            }
            .padding(.leading, 4)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }
}

private extension DeliveryMethod {
    var detailIcon: String {
        switch self {
        case .vaginal: "hands.and.sparkles.fill"
        case .cSection: "scissors"
        case .vBac: "arrow.triangle.2.circlepath"
        }
    }
}
#endif
