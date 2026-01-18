// DeliveryDetailHeaderView.swift
// Stork
//
// Created by Nick Molargik on 10/6/25.
//

import SwiftUI

struct DeliveryDetailHeaderView: View {
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false

    let delivery: Delivery

    private var babyCount: Int {
        delivery.babies?.count ?? delivery.babyCount
    }

    var body: some View {
        VStack(spacing: 14) {
            // Top chips: date + baby count
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(delivery.date.formattedForDelivery(useDayMonthYear: useDayMonthYearDates))
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Delivery date: \(delivery.date.formattedForDelivery(useDayMonthYear: useDayMonthYearDates))")

                HStack(spacing: 6) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(babyCount) Bab\(babyCount == 1 ? "y" : "ies")")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(babyCount) bab\(babyCount == 1 ? "y" : "ies") delivered")
            }

            // Stats row styled like Home cards
            HStack(spacing: 12) {
                VStack(alignment: .center, spacing: 4) {
                    Label("Delivery Method", systemImage: "hands.and.sparkles.fill")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Delivery method: \(delivery.deliveryMethod.displayName)")

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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Epidural: \(delivery.epiduralUsed ? "Yes" : "No")")
            }

            // Tags row
            if let tags = delivery.tags, !tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tags", systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(tags) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tags: \(tags.map { $0.name }.joined(separator: ", "))")
            }

            // Notes section
            if let notes = delivery.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes", systemImage: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Notes: \(notes)")
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
}

#Preview {
    DeliveryDetailHeaderView(delivery: Delivery.sample())
}
