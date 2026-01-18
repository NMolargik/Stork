//
//  ShareCardView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct ShareCardView: View {
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(UserManager.self) private var userManager
    @Environment(ExportManager.self) private var exportManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @State private var selectedCard: CardImageRenderer.CardType?
    @State private var selectedMilestone: MilestoneOption?
    @State private var renderedImage: UIImage?
    @State private var includeWatermark: Bool = true

    private var totalBabies: Int {
        deliveryManager.deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }

    private var totalDeliveries: Int {
        deliveryManager.deliveries.count
    }

    private var availableMilestones: [MilestoneOption] {
        var milestones: [MilestoneOption] = []

        // Baby milestones
        let babyMilestones = [50, 100, 250, 500, 1000, 2500, 5000]
        for milestone in babyMilestones where totalBabies >= milestone {
            milestones.append(MilestoneOption(count: milestone, type: .babies))
        }

        // Delivery milestones
        let deliveryMilestones = [25, 50, 100, 250, 500, 1000]
        for milestone in deliveryMilestones where totalDeliveries >= milestone {
            milestones.append(MilestoneOption(count: milestone, type: .deliveries))
        }

        return milestones.sorted { $0.count > $1.count }
    }

    var body: some View {
        List {
            // Stat Cards Section
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(CardImageRenderer.CardType.allCases) { cardType in
                        CardThumbnail(cardType: cardType, isSelected: selectedCard == cardType)
                            .onTapGesture {
                                selectStatCard(cardType)
                            }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Statistics Cards")
            } footer: {
                Text("Tap a card to preview and share it.")
            }

            // Milestones Section
            if !availableMilestones.isEmpty {
                Section {
                    ForEach(availableMilestones) { milestone in
                        Button {
                            selectMilestone(milestone)
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading) {
                                    Text("\(milestone.count) \(milestone.type.displayName)")
                                        .font(.headline)
                                    Text(milestone.type.displayTemplate(count: milestone.count))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedMilestone == milestone {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Milestones Achieved")
                } footer: {
                    Text("Share your achievements with colleagues!")
                }
            }

            // Options Section
            Section {
                Toggle("Include Watermark", isOn: $includeWatermark)
                    .onChange(of: includeWatermark) { _, _ in
                        regenerateImage()
                    }
            } header: {
                Text("Options")
            }

            // Share Section
            if let image = renderedImage {
                Section {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)

                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("Stork Statistics", image: Image(uiImage: image))
                        ) {
                            Label("Share Image", systemImage: "square.and.arrow.up")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.storkBlue)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
        }
        .navigationTitle("Share Cards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectStatCard(_ cardType: CardImageRenderer.CardType) {
        selectedCard = cardType
        selectedMilestone = nil

        renderedImage = exportManager.renderStatCard(
            type: cardType,
            deliveries: deliveryManager.deliveries,
            useMetricUnits: useMetricUnits,
            includeWatermark: includeWatermark
        )
        Haptics.lightImpact()
    }

    private func selectMilestone(_ milestone: MilestoneOption) {
        selectedMilestone = milestone
        selectedCard = nil

        let userName = userManager.currentUser.map { "\($0.firstName) \($0.lastName)" }
        renderedImage = exportManager.renderMilestoneCard(
            count: milestone.count,
            milestoneType: milestone.type,
            userName: userName
        )
        Haptics.lightImpact()
    }

    private func regenerateImage() {
        if let card = selectedCard {
            selectStatCard(card)
        } else if let milestone = selectedMilestone {
            selectMilestone(milestone)
        }
    }
}

// MARK: - Supporting Types

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
            Image(systemName: cardType.iconName)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : accentColor)

            Text(cardType.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? accentColor : Color(uiColor: .tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? accentColor : .clear, lineWidth: 2)
        )
    }

    private var accentColor: Color {
        switch cardType {
        case .deliveryMethod: return .storkBlue
        case .sexDistribution: return .storkPurple
        case .babyCount: return .storkPink
        case .epiduralUsage, .nicuStay: return .red
        case .babyMeasurements: return .storkOrange
        }
    }
}

#Preview {
    NavigationStack {
        ShareCardView()
            .environment(DeliveryManager(context: PreviewContainer.shared.mainContext))
            .environment(UserManager(context: PreviewContainer.shared.mainContext))
            .environment(ExportManager())
    }
}

private enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
