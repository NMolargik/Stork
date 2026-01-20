//
//  CardImageRenderer.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import SwiftUI

@MainActor
final class CardImageRenderer {

    enum CardType: String, CaseIterable, Identifiable {
        case deliveryMethod
        case sexDistribution
        case babyCount
        case epiduralUsage
        case nicuStay
        case babyMeasurements

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .deliveryMethod: return "Delivery Method"
            case .sexDistribution: return "Sex Distribution"
            case .babyCount: return "Baby Count"
            case .epiduralUsage: return "Epidural Usage"
            case .nicuStay: return "NICU Stays"
            case .babyMeasurements: return "Baby Measurements"
            }
        }

        var iconName: String {
            switch self {
            case .deliveryMethod: return "hands.and.sparkles.fill"
            case .sexDistribution: return "chart.pie.fill"
            case .babyCount: return "figure.2.and.child.holdinghands"
            case .epiduralUsage: return "syringe.fill"
            case .nicuStay: return "bed.double"
            case .babyMeasurements: return "ruler"
            }
        }
    }

    enum MilestoneType: String, CaseIterable, Identifiable {
        case babies
        case deliveries

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .babies: return "Babies"
            case .deliveries: return "Deliveries"
            }
        }

        func displayTemplate(count: Int) -> String {
            switch self {
            case .babies:
                return "I've delivered \(count) \(count == 1 ? "baby" : "babies")!"
            case .deliveries:
                return "I've completed \(count) \(count == 1 ? "delivery" : "deliveries")!"
            }
        }
    }

    func renderCard(
        type: CardType,
        deliveries: [Delivery],
        useMetricUnits: Bool,
        includeWatermark: Bool = true
    ) -> UIImage? {
        let cardView = ShareableStatCardView(
            cardType: type,
            deliveries: deliveries,
            useMetricUnits: useMetricUnits,
            includeWatermark: includeWatermark
        )

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0 // High resolution

        return renderer.uiImage
    }

    func renderMilestoneCard(
        count: Int,
        milestoneType: MilestoneType
    ) -> UIImage? {
        let cardView = MilestoneCardView(
            count: count,
            milestoneType: milestoneType
        )
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0

        return renderer.uiImage
    }
}

// MARK: - Shareable Stat Card View (for rendering)

struct ShareableStatCardView: View {
    let cardType: CardImageRenderer.CardType
    let deliveries: [Delivery]
    let useMetricUnits: Bool
    let includeWatermark: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: cardType.iconName)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                Text(cardType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Content based on card type
            cardContent

            if includeWatermark {
                HStack {
                    Spacer()
                    Image("storkicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
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

    @ViewBuilder
    private var cardContent: some View {
        switch cardType {
        case .deliveryMethod:
            deliveryMethodContent
        case .sexDistribution:
            sexDistributionContent
        case .babyCount:
            babyCountContent
        case .epiduralUsage:
            epiduralContent
        case .nicuStay:
            nicuContent
        case .babyMeasurements:
            measurementsContent
        }
    }

    // MARK: - Card Contents

    private var deliveryMethodContent: some View {
        let total = deliveries.count
        let vaginal = deliveries.filter { $0.deliveryMethod == .vaginal }.count
        let cSection = deliveries.filter { $0.deliveryMethod == .cSection }.count
        let vbac = deliveries.filter { $0.deliveryMethod == .vBac }.count

        return VStack(alignment: .leading, spacing: 12) {
            if total > 0 {
                // Bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.storkBlue)
                            .frame(width: geo.size.width * CGFloat(vaginal) / CGFloat(total))
                        Rectangle()
                            .fill(Color.storkOrange)
                            .frame(width: geo.size.width * CGFloat(cSection) / CGFloat(total))
                        Rectangle()
                            .fill(Color.storkPurple)
                            .frame(width: geo.size.width * CGFloat(vbac) / CGFloat(total))
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 16)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .storkBlue, label: "Vaginal", value: vaginal, total: total)
                    legendItem(color: .storkOrange, label: "C-Section", value: cSection, total: total)
                    legendItem(color: .storkPurple, label: "VBAC", value: vbac, total: total)
                }
                .font(.caption)
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func legendItem(color: Color, label: String, value: Int, total: Int) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label): \(String(format: "%.0f", Double(value) / Double(total) * 100))%")
        }
    }

    private var sexDistributionContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count
        let male = babies.filter { $0.sex == .male }.count
        let female = babies.filter { $0.sex == .female }.count
        let loss = babies.filter { $0.sex == .loss }.count

        return VStack(spacing: 12) {
            if total > 0 {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(male)")
                            .font(.title2.bold())
                            .foregroundStyle(.storkBlue)
                        Text("Boys")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(female)")
                            .font(.title2.bold())
                            .foregroundStyle(.storkPink)
                        Text("Girls")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if loss > 0 {
                        VStack {
                            Text("\(loss)")
                                .font(.title2.bold())
                                .foregroundStyle(.storkPurple)
                            Text("Loss")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Text("\(total) total babies")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var babyCountContent: some View {
        let total = deliveries.count
        let babies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        let avg = total > 0 ? Double(babies) / Double(total) : 0

        return VStack(spacing: 8) {
            Text(String(format: "%.1f", avg))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.storkPink)
            Text("babies per delivery")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(total) deliveries, \(babies) babies")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var epiduralContent: some View {
        let total = deliveries.count
        let epidural = deliveries.filter { $0.epiduralUsed }.count
        let percent = total > 0 ? Double(epidural) / Double(total) * 100 : 0

        return VStack(spacing: 8) {
            Text(String(format: "%.1f%%", percent))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.red)
            Text("epidural usage")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var nicuContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count
        let nicu = babies.filter { $0.nicuStay }.count
        let percent = total > 0 ? Double(nicu) / Double(total) * 100 : 0

        return VStack(spacing: 8) {
            Text(String(format: "%.1f%%", percent))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.red)
            Text("NICU stays")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var measurementsContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count

        guard total > 0 else {
            return AnyView(
                Text("No data")
                    .foregroundStyle(.secondary)
            )
        }

        let avgWeight = babies.reduce(0.0) { $0 + $1.weight } / Double(total)
        let avgHeight = babies.reduce(0.0) { $0 + $1.height } / Double(total)

        let weightStr = UnitConversion.weightDisplay(avgWeight, useMetric: useMetricUnits)
        let heightStr = UnitConversion.heightDisplay(avgHeight, useMetric: useMetricUnits)

        return AnyView(
            HStack(spacing: 24) {
                VStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(.storkOrange)
                    Text(weightStr)
                        .font(.title3.bold())
                    Text("avg weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Image(systemName: "ruler.fill")
                        .foregroundStyle(.storkOrange)
                    Text(heightStr)
                        .font(.title3.bold())
                    Text("avg height")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }
}
