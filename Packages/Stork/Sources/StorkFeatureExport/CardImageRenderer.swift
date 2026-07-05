//
//  CardImageRenderer.swift
//  StorkFeatureExport
//
//  Renders shareable statistic and milestone cards to `UIImage` via `ImageRenderer`.
//

#if os(iOS)
import Foundation
import SwiftUI
import StorkCore
import StorkDesignSystem

@MainActor
public final class CardImageRenderer {

    public enum CardType: String, CaseIterable, Identifiable, Sendable {
        case deliveryMethod, sexDistribution, babyCount, epiduralUsage, nicuStay, babyMeasurements

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .deliveryMethod: "Delivery Method"
            case .sexDistribution: "Sex Distribution"
            case .babyCount: "Baby Count"
            case .epiduralUsage: "Epidural Usage"
            case .nicuStay: "NICU Stays"
            case .babyMeasurements: "Baby Measurements"
            }
        }

        public var iconName: String {
            switch self {
            case .deliveryMethod: "hands.and.sparkles.fill"
            case .sexDistribution: "chart.pie.fill"
            case .babyCount: "figure.2.and.child.holdinghands"
            case .epiduralUsage: "syringe.fill"
            case .nicuStay: "bed.double"
            case .babyMeasurements: "ruler"
            }
        }
    }

    public enum MilestoneType: String, CaseIterable, Identifiable, Sendable {
        case babies, deliveries

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .babies: "Babies"
            case .deliveries: "Deliveries"
            }
        }

        public func displayTemplate(count: Int) -> String {
            switch self {
            case .babies: "I've delivered \(count) \(count == 1 ? "baby" : "babies")!"
            case .deliveries: "I've completed \(count) \(count == 1 ? "delivery" : "deliveries")!"
            }
        }
    }

    public init() {}

    public func renderCard(type: CardType, deliveries: [Delivery], useMetricUnits: Bool, includeWatermark: Bool = true) -> UIImage? {
        let renderer = ImageRenderer(content: ShareableStatCardView(cardType: type, deliveries: deliveries, useMetricUnits: useMetricUnits, includeWatermark: includeWatermark))
        renderer.scale = 3.0
        return renderer.uiImage
    }

    public func renderMilestoneCard(count: Int, milestoneType: MilestoneType) -> UIImage? {
        let renderer = ImageRenderer(content: MilestoneCardView(count: count, milestoneType: milestoneType).environment(\.colorScheme, .light))
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

// MARK: - Shareable stat card

struct ShareableStatCardView: View {
    let cardType: CardImageRenderer.CardType
    let deliveries: [Delivery]
    let useMetricUnits: Bool
    let includeWatermark: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: cardType.iconName).font(.title2).foregroundStyle(accentColor)
                Text(cardType.displayName).font(.headline).fontWeight(.semibold)
                Spacer()
            }
            cardContent
            if includeWatermark {
                HStack {
                    Spacer()
                    Image("storkicon").resizable().scaledToFit().frame(width: 20, height: 20)
                }
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(uiColor: .systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
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

    @ContentBuilder
    private var cardContent: some View {
        switch cardType {
        case .deliveryMethod: deliveryMethodContent
        case .sexDistribution: sexDistributionContent
        case .babyCount: babyCountContent
        case .epiduralUsage: epiduralContent
        case .nicuStay: nicuContent
        case .babyMeasurements: measurementsContent
        }
    }

    private var deliveryMethodContent: some View {
        let total = deliveries.count
        let vaginal = deliveries.count { $0.deliveryMethod == .vaginal }
        let cSection = deliveries.count { $0.deliveryMethod == .cSection }
        let vbac = deliveries.count { $0.deliveryMethod == .vBac }
        return VStack(alignment: .leading, spacing: 12) {
            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.storkBlue).frame(width: geo.size.width * CGFloat(vaginal) / CGFloat(total))
                        Rectangle().fill(Color.storkOrange).frame(width: geo.size.width * CGFloat(cSection) / CGFloat(total))
                        Rectangle().fill(Color.storkPurple).frame(width: geo.size.width * CGFloat(vbac) / CGFloat(total))
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 16)
                HStack(spacing: 16) {
                    legendItem(color: .storkBlue, label: String(localized: "Vaginal", bundle: .module), value: vaginal, total: total)
                    legendItem(color: .storkOrange, label: String(localized: "C-Section", bundle: .module), value: cSection, total: total)
                    legendItem(color: .storkPurple, label: String(localized: "VBAC", bundle: .module), value: vbac, total: total)
                }
                .font(.caption)
            } else {
                Text("No data", bundle: .module).foregroundStyle(.secondary)
            }
        }
    }

    private func legendItem(color: Color, label: String, value: Int, total: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label): \(String(format: "%.0f", Double(value) / Double(total) * 100))%", bundle: .module)
        }
    }

    private var sexDistributionContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count
        let male = babies.count { $0.sex == .male }
        let female = babies.count { $0.sex == .female }
        let loss = babies.count { $0.sex == .loss }
        return VStack(spacing: 12) {
            if total > 0 {
                HStack(spacing: 20) {
                    statColumn(value: male, label: String(localized: "Boys", bundle: .module), color: .storkBlue)
                    statColumn(value: female, label: String(localized: "Girls", bundle: .module), color: .storkPink)
                    if loss > 0 { statColumn(value: loss, label: String(localized: "Loss", bundle: .module), color: .storkPurple) }
                }
                Text("\(total) total babies", bundle: .module).font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No data", bundle: .module).foregroundStyle(.secondary)
            }
        }
    }

    private func statColumn(value: Int, label: String, color: Color) -> some View {
        VStack {
            Text("\(value)", bundle: .module).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var babyCountContent: some View {
        let total = deliveries.count
        let babies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        let avg = total > 0 ? Double(babies) / Double(total) : 0
        return VStack(spacing: 8) {
            Text(String(format: "%.1f", avg)).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.storkPink)
            Text("babies per delivery", bundle: .module).font(.subheadline).foregroundStyle(.secondary)
            Text("\(total) deliveries, \(babies) babies", bundle: .module).font(.caption).foregroundStyle(.tertiary)
        }
    }

    private var epiduralContent: some View {
        let total = deliveries.count
        let epidural = deliveries.count { $0.epiduralUsed }
        let percent = total > 0 ? Double(epidural) / Double(total) * 100 : 0
        return VStack(spacing: 8) {
            Text(String(format: "%.1f%%", percent)).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.red)
            Text("epidural usage", bundle: .module).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var nicuContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count
        let nicu = babies.count { $0.nicuStay }
        let percent = total > 0 ? Double(nicu) / Double(total) * 100 : 0
        return VStack(spacing: 8) {
            Text(String(format: "%.1f%%", percent)).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.red)
            Text("NICU stays", bundle: .module).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var measurementsContent: some View {
        let babies = deliveries.flatMap { $0.babies ?? [] }
        let total = babies.count
        guard total > 0 else {
            return AnyView(Text("No data", bundle: .module).foregroundStyle(.secondary))
        }
        let avgWeight = babies.reduce(0.0) { $0 + $1.weight } / Double(total)
        let avgHeight = babies.reduce(0.0) { $0 + $1.height } / Double(total)
        return AnyView(
            HStack(spacing: 24) {
                VStack {
                    Image(systemName: "scalemass.fill").foregroundStyle(.storkOrange)
                    Text(UnitConversion.weightDisplay(avgWeight, useMetric: useMetricUnits)).font(.title3.bold())
                    Text("avg weight", bundle: .module).font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Image(systemName: "ruler.fill").foregroundStyle(.storkOrange)
                    Text(UnitConversion.heightDisplay(avgHeight, useMetric: useMetricUnits)).font(.title3.bold())
                    Text("avg height", bundle: .module).font(.caption).foregroundStyle(.secondary)
                }
            }
        )
    }
}
#endif
