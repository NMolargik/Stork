//
//  ShareCardView.swift
//  StorkFeatureExport
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct ShareCardView: View {
    let model: ExportModel
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @Environment(\.requestProUpgrade) private var requestProUpgrade

    @State private var selectedCard: CardImageRenderer.CardType?
    @State private var selectedMilestone: MilestoneOption?
    @State private var renderedImage: UIImage?
    @State private var includeWatermark = true
    @State private var milestoneShareImage: IdentifiableImage?

    private var totalBabies: Int { model.totalBabies }
    private var totalDeliveries: Int { model.deliveries.count }

    private var availableMilestones: [MilestoneOption] {
        var milestones: [MilestoneOption] = []
        for m in [50, 100, 250, 500, 1000, 2500, 5000] where totalBabies >= m {
            milestones.append(MilestoneOption(count: m, type: .babies))
        }
        for m in [25, 50, 100, 250, 500, 1000] where totalDeliveries >= m {
            milestones.append(MilestoneOption(count: m, type: .deliveries))
        }
        return milestones.sorted { $0.count > $1.count }
    }

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(CardImageRenderer.CardType.allCases) { cardType in
                        CardThumbnail(cardType: cardType, isSelected: selectedCard == cardType)
                            .onTapGesture { selectStatCard(cardType) }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Statistics Cards", bundle: .module)
            } footer: {
                Text("Tap a card to preview and share it.", bundle: .module)
            }

            if !availableMilestones.isEmpty {
                Section {
                    ForEach(availableMilestones) { milestone in
                        Button {
                            if model.isProUnlocked {
                                selectMilestone(milestone)
                            } else {
                                Haptics.lightImpact()
                                requestProUpgrade(.milestoneShareCards)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                VStack(alignment: .leading) {
                                    Text("\(milestone.count) \(milestone.type.displayName)", bundle: .module).font(.headline)
                                    Text(milestone.type.displayTemplate(count: milestone.count)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !model.isProUnlocked {
                                    ProBadge()
                                } else if selectedMilestone == milestone {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(model.isProUnlocked ? Text(verbatim: "") : Text("Locked. Unlock with Stork Pro.", bundle: .module))
                    }
                } header: {
                    Text("Milestones Achieved", bundle: .module)
                } footer: {
                    if model.isProUnlocked {
                        Text("Share your achievements with colleagues!", bundle: .module)
                    } else {
                        Text("Career milestone cards are part of Stork Pro.", bundle: .module)
                    }
                }
            }

            Section(String(localized: "Options", bundle: .module)) {
                Toggle(String(localized: "Include Watermark", bundle: .module), isOn: $includeWatermark)
                    .onChange(of: includeWatermark) { _, _ in regenerateImage() }
            }

            if let image = renderedImage {
                Section(String(localized: "Preview", bundle: .module)) {
                    VStack {
                        Image(uiImage: image)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)
                        if selectedMilestone != nil {
                            // Milestone cards go through ShareSheet so a completed share can
                            // trigger the one-time review prompt.
                            Button {
                                milestoneShareImage = IdentifiableImage(image: image)
                            } label: {
                                Label(String(localized: "Share Image", bundle: .module), systemImage: "square.and.arrow.up")
                                    .foregroundStyle(.white).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.storkBlue)
                            .padding(.top, 8)
                        } else {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview("Stork Statistics", image: Image(uiImage: image))) {
                                Label(String(localized: "Share Image", bundle: .module), systemImage: "square.and.arrow.up")
                                    .foregroundStyle(.white).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.storkBlue)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(Text("Share Cards", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $milestoneShareImage) { item in
            ShareSheet(items: [item.image]) { completed in
                if completed { model.noteMilestoneCardShared() }
            }
        }
    }

    private func selectStatCard(_ cardType: CardImageRenderer.CardType) {
        selectedCard = cardType
        selectedMilestone = nil
        renderedImage = model.manager.renderStatCard(type: cardType, deliveries: model.deliveries, useMetricUnits: useMetricUnits, includeWatermark: includeWatermark)
        Haptics.lightImpact()
    }

    private func selectMilestone(_ milestone: MilestoneOption) {
        selectedMilestone = milestone
        selectedCard = nil
        renderedImage = model.manager.renderMilestoneCard(count: milestone.count, milestoneType: milestone.type)
        Haptics.lightImpact()
    }

    private func regenerateImage() {
        if let card = selectedCard { selectStatCard(card) }
        else if let milestone = selectedMilestone { selectMilestone(milestone) }
    }
}

struct MilestoneOption: Identifiable, Equatable {
    let count: Int
    let type: CardImageRenderer.MilestoneType
    var id: String { "\(type.rawValue)-\(count)" }
}

struct CardThumbnail: View {
    let cardType: CardImageRenderer.CardType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: cardType.iconName).font(.title2).foregroundStyle(isSelected ? .white : accentColor)
            Text(cardType.displayName).font(.caption).multilineTextAlignment(.center).foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isSelected ? accentColor : Color(uiColor: .tertiarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(isSelected ? accentColor : .clear, lineWidth: 2))
    }

    private var accentColor: Color {
        switch cardType {
        case .deliveryMethod: .storkBlue
        case .sexDistribution: .storkPurple
        case .babyCount: .storkPink
        case .epiduralUsage, .nicuStay: .red
        case .babyMeasurements: .storkOrange
        }
    }
}
#endif
