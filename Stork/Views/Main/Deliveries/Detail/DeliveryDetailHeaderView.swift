// DeliveryDetailHeaderView.swift
// Stork
//
// Created by Nick Molargik on 10/6/25.
//

import SwiftUI

struct DeliveryDetailHeaderView: View {
    @Environment(HospitalManager.self) private var hospitalManager: HospitalManager
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    
    let delivery: Delivery
    
    var body: some View {
        VStack(spacing: 14) {
            // Top chips: date + hospital
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Date").font(.caption2).foregroundStyle(.secondary)
                        Text(formattedDate(delivery.date))
                            .font(.subheadline).fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )

                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Hospital").font(.caption2).foregroundStyle(.secondary)
                        Text({ () -> String in
                            if let id = delivery.hospitalId,
                               let resolved = hospitalManager.hospitals.first(where: { $0.remoteId == id }) {
                                return resolved.facilityName
                            }
                            return "No Hospital Specified"
                        }())
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
            }

            // Stats row styled like Home cards
            HStack(spacing: 12) {
                VStack(alignment: .center, spacing: 4) {
                    Label("Delivery Method", systemImage: "figure.and.child.holdinghands")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(delivery.deliveryMethod.displayName.capitalized)
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )

                VStack(alignment: .center, spacing: 4) {
                    Label("Epidural", systemImage: "syringe.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(delivery.epiduralUsed ? "Yes" : "No")
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Delivery details")
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if useDayMonthYearDates {
            formatter.dateFormat = "dd/MM/yyyy, h:mm a"
        } else {
            formatter.dateStyle = .long
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
}

#Preview {
    DeliveryDetailHeaderView(delivery: Delivery.sample())
        .environment(HospitalManager())
}
