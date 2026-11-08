//
//  EstimatedBirthsRow.swift
//  StorkFeatureDeliveries
//
//  A past-births summary in the delivery list: one quiet card per estimated year, clearly
//  marked Estimated, with no date, time or detail to pretend to.
//

import SwiftUI
import StorkCore

struct EstimatedBirthsRow: View {
    let delivery: Delivery

    private var year: String {
        String(Calendar.current.component(.year, from: delivery.date))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(year).font(.headline.monospacedDigit())
                    Text("Estimated", bundle: .module)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(.secondary.opacity(0.18)))
                }
                Text("About ^[\(delivery.deliveryWeight) birth](inflect: true) · ^[\(delivery.babyCount) baby](inflect: true)", bundle: .module)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if let role = delivery.role {
                Text(role.shortName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(.secondary.opacity(0.18)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Estimated past births. Swipe to delete.", bundle: .module))
    }
}
