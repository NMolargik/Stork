//
//  DeliveryMethodCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct DeliveryMethodCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "Delivery Method", bundle: .module), systemImage: "hands.and.sparkles.fill", accent: .storkBlue) {
            let stats = DeliveryStatistics.deliveryMethodStats(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    let v = stats.vaginalPercentage
                    let c = stats.cSectionPercentage
                    let vb = stats.vBacPercentage

                    AnimatedProgressBar(segments: [
                        .init(value: v, color: DeliveryMethod.vaginal.accentColor),
                        .init(value: c, color: DeliveryMethod.cSection.accentColor),
                        .init(value: vb, color: DeliveryMethod.vBac.accentColor),
                    ])
                    .accessibilityHidden(true)

                    FlowLayout(spacing: 8) {
                        MethodPill(label: String(localized: "Vaginal", bundle: .module), value: v, color: DeliveryMethod.vaginal.accentColor)
                        MethodPill(label: String(localized: "C-Section", bundle: .module), value: c, color: DeliveryMethod.cSection.accentColor)
                        MethodPill(label: String(localized: "VBAC", bundle: .module), value: vb, color: DeliveryMethod.vBac.accentColor)
                    }
                    .font(.caption)
                } else {
                    EmptyCardLabel()
                }
            }
        }
    }

    private struct MethodPill: View {
        let label: String
        let value: Double
        let color: Color

        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill").font(.caption2).accessibilityHidden(true)
                Text(label)
                AnimatedNumber(value: value, format: "%.0f", font: .caption, fontWeight: .regular, color: color)
                Text("%", bundle: .module)
            }
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label) deliveries: \(String(format: "%.0f", value)) percent")
        }
    }
}

/// Shared "nothing logged yet" placeholder for dashboard cards.
struct EmptyCardLabel: View {
    var body: some View {
        Label(String(localized: "No deliveries logged yet.", bundle: .module), systemImage: "tray.fill")
            .foregroundStyle(.secondary)
            .labelStyle(.titleOnly)
    }
}
#endif
