//
//  RoleBreakdownCard.swift
//  StorkFeatureDashboard
//
//  Deliveries and babies per role, plus the headline total honoring the Settings choice
//  of which roles count.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct RoleBreakdownCard: View {
    let deliveries: [Delivery]
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    var body: some View {
        InsightCard(title: String(localized: "My Role", bundle: .module), systemImage: "person.2.badge.gearshape", accent: .storkPurple) {
            let counting = BirthRoleCounting(storedValue: excludedRoles)
            let stats = DeliveryStatistics.roleBreakdown(deliveries: deliveries)
            let headline = DeliveryStatistics.totals(deliveries: deliveries, counting: counting)
            if stats.isEmpty {
                Text("Record your role on a delivery to see it here.", bundle: .module)
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(headline.deliveries) deliveries • \(headline.babies) babies counted", bundle: .module)
                        .font(.footnote).foregroundStyle(.secondary)
                    ForEach(stats) { stat in
                        HStack {
                            Label(stat.role.displayName, systemImage: stat.role.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(counting.counts(stat.role) ? Color.primary : Color.secondary)
                            Spacer()
                            Text(verbatim: "\(stat.deliveries) • \(stat.babies)")
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(stat.role.displayName): \(stat.deliveries) deliveries, \(stat.babies) babies", bundle: .module))
                    }
                }
            }
        }
    }
}
#endif
