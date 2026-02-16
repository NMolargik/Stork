//
//  DeliveryDetailView.swift
//  Stork
//

import SwiftUI
import SwiftData

// MARK: - Platform-adaptive colors
private var secondaryGroupedBackground: Color {
    #if os(watchOS)
    Color(.darkGray)
    #else
    Color(uiColor: .secondarySystemGroupedBackground)
    #endif
}

struct DeliveryDetailView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    var delivery: Delivery
    var onClose: (() -> Void)?

    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage: String?
    @State private var showEditSheet = false

    private var babies: [Baby] {
        delivery.babies ?? []
    }

    private var babyCount: Int {
        babies.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                contentSection
            }
        }
        #if os(watchOS)
        .background(Color(.black))
        #else
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
        .navigationTitle("Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .alert("Delete this delivery?", isPresented: $showDeleteConfirm) {
            deleteAlert
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't delete delivery", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "An unknown error occurred. Please try again.")
        }
        .sheet(isPresented: $showEditSheet) {
            DeliveryEditFormView(delivery: delivery)
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Hero Header

    @ViewBuilder
    private var heroHeader: some View {
        VStack(spacing: 0) {
            // Gradient background with date (colors based on baby sex distribution)
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(0.15))
                )

                VStack(spacing: 8) {
                    // Large date display
                    Text(delivery.date.formatted(.dateTime.hour().minute()) + " - " + delivery.date.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))

                    Text(delivery.date.formatted(.dateTime.month(.wide).day()))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(delivery.date.formatted(.dateTime.year()))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.vertical, 32)
            }
            .frame(maxWidth: .infinity)

            // Quick stats pills overlapping the gradient
            quickStatsRow
                .padding(.horizontal, 16)
                .offset(y: -24)
        }
    }

    /// Gradient colors based on baby sex distribution, matching DeliveryRowView styling
    private var gradientColors: [Color] {
        let maleCount = babies.filter { $0.sex == .male }.count
        let femaleCount = babies.filter { $0.sex == .female }.count
        let lossCount = babies.filter { $0.sex == .loss }.count

        var colors = Array(repeating: Color("storkBlue"), count: maleCount) +
                     Array(repeating: Color("storkPink"), count: femaleCount) +
                     Array(repeating: Color("storkPurple"), count: lossCount)

        if colors.count == 1, let onlyColor = colors.first {
            colors = [onlyColor, onlyColor.opacity(0.8)]
        } else if colors.isEmpty {
            colors = [Color.gray.opacity(0.7), Color.gray.opacity(0.5)]
        }

        return colors
    }

    private var deliveryAccentColor: Color {
        switch delivery.deliveryMethod {
        case .vaginal:
            return .storkPink
        case .cSection:
            return .storkPurple
        case .vBac:
            return .storkBlue
        }
    }

    @ViewBuilder
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            // Baby count
            statPill(
                icon: "figure.and.child.holdinghands",
                value: "\(babyCount)",
                label: babyCount == 1 ? "Baby" : "Babies",
                color: .storkBlue
            )

            // Delivery method
            statPill(
                icon: delivery.deliveryMethod.icon,
                value: delivery.deliveryMethod.shortName,
                label: "Method",
                color: deliveryAccentColor
            )

            // Epidural
            statPill(
                icon: "syringe.fill",
                value: delivery.epiduralUsed ? "Yes" : "No",
                label: "Epidural",
                color: delivery.epiduralUsed ? .red : .secondary
            )
        }
    }

    @ViewBuilder
    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(height: 30)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: 85)
        .modifier(StatPillBackground())
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 20) {
            // Babies section
            if !babies.isEmpty {
                babiesSection
            }

            // Tags section
            if let tags = delivery.tags, !tags.isEmpty {
                tagsSection(tags)
            }

            // Notes section
            if let notes = delivery.notes, !notes.isEmpty {
                notesSection(notes)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var babiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Babies", icon: "heart.fill", color: .pink)

            ForEach(Array(babies.enumerated()), id: \.element.id) { index, baby in
                babyCard(baby, index: index + 1)
            }
        }
    }

    @ViewBuilder
    private func babyCard(_ baby: Baby, index: Int) -> some View {
        VStack(spacing: 0) {
            // Header with sex indicator
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(baby.sex.color)
                        .frame(width: 12, height: 12)

                    Text("Baby \(index)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(baby.sex.displayName))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Birthday time
                Text(baby.birthday.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(baby.sex.color.opacity(0.1))

            // Measurements
            HStack(spacing: 0) {
                // Weight
                VStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .foregroundStyle(.storkOrange)
                    Text(UnitConversion.weightDisplay(baby.weight, useMetric: useMetricUnits))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Weight")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                Divider()
                    .frame(height: 50)

                // Length
                VStack(spacing: 4) {
                    Image(systemName: "ruler")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text(UnitConversion.heightDisplay(baby.height, useMetric: useMetricUnits))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Length")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // Special indicators
            if baby.nurseCatch || baby.nicuStay {
                Divider()
                HStack(spacing: 12) {
                    if baby.nurseCatch {
                        Label("Nurse Catch", systemImage: "stethoscope")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.red.gradient, in: Capsule())
                    }
                    if baby.nicuStay {
                        Label("NICU Stay", systemImage: "bed.double.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.gradient, in: Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func tagsSection(_ tags: [DeliveryTag]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Tags", icon: "tag.fill", color: .storkPurple)

            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 8, height: 8)
                        Text(tag.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(tag.color.opacity(0.15))
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes", icon: "note.text", color: .storkOrange)

            VStack(alignment: .leading, spacing: 8) {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(.leading, 4)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Only show custom close button when presented modally (onClose provided)
        if hSizeClass == .regular, let onClose {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Close")
                    }
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.green)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    // MARK: - Alerts

    @ViewBuilder
    private var deleteAlert: some View {
        Button("Delete", role: .destructive) {
            if let onClose {
                onClose()
            } else {
                dismiss()
            }
            deliveryManager.delete(delivery)
        }
        Button("Cancel", role: .cancel) { }
    }
}

// MARK: - DeliveryMethod Extension

private extension DeliveryMethod {
    var icon: String {
        switch self {
        case .vaginal:
            return "square.and.arrow.up"
        case .cSection:
            return "scissors"
        case .vBac:
            return "arrow.triangle.2.circlepath"
        }
    }

    var shortName: String {
        switch self {
        case .vaginal:
            return "Vaginal"
        case .cSection:
            return "C-Section"
        case .vBac:
            return "VBAC"
        }
    }
}

// MARK: - Preview

#Preview("Delivery Detail") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    NavigationStack {
        DeliveryDetailView(delivery: Delivery.sample())
            .environment(DeliveryManager(context: context))
    }
}

#Preview("Delivery Detail - Multiple Babies") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    let delivery = Delivery.sample()
    // The sample already has 3 babies

    NavigationStack {
        DeliveryDetailView(delivery: delivery)
            .environment(DeliveryManager(context: context))
    }
}
