//
//  DeliveryRowView.swift
//  StorkFeatureDeliveries
//
//  A gradient delivery card: date/time title, sex-dot summary capsule, and NICU /
//  epidural / C-section badges.
//

import SwiftUI
import StorkCore
import StorkDesignSystem

struct DeliveryRowView: View {
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false

    let delivery: Delivery
    @State private var model: DeliveryRowModel

    init(delivery: Delivery) {
        self.delivery = delivery
        _model = State(wrappedValue: DeliveryRowModel(delivery: delivery))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(model.primaryTitle(useDayMonthYear: useDayMonthYearDates))
                        .font(.subheadline)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }

                HStack {
                    if model.hasSecondary {
                        HStack(alignment: .center, spacing: 8) {
                            SexDots(model: model)
                            Text(model.babySummary)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.ultraThinMaterial).shadow(color: .black.opacity(0.1), radius: 2))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Badge(name: model.nicuSymbolName, label: String(localized: "NICU", bundle: .module), model: model)
                        Badge(name: model.epiduralSymbolName, label: String(localized: "Epidural", bundle: .module), model: model)
                        Badge(name: model.cSectionSymbolName, label: String(localized: "C-section", bundle: .module), model: model)
                    }
                }
            }
            .padding(.horizontal, 8)

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.7))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: model.gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.15)))
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onChange(of: delivery.babyCount) { _, _ in model = DeliveryRowModel(delivery: delivery) }
        .onChange(of: delivery.babies?.count ?? 0) { _, _ in model = DeliveryRowModel(delivery: delivery) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilitySummary)
    }

    private struct Badge: View {
        let name: String?
        let label: String
        let model: DeliveryRowModel

        var body: some View {
            if let name {
                Image(systemName: name)
                    .imageScale(.small)
                    .frame(width: 10)
                    .foregroundStyle(model.iconForegroundColor)
                    .padding(6)
                    .background(Circle().fill(model.iconBackgroundColor))
                    .accessibilityLabel(label)
            }
        }
    }

    private struct SexDots: View {
        let model: DeliveryRowModel

        var body: some View {
            let segments = model.dotSegments
            let total = segments.reduce(0) { $0 + $1.count }
            if total == 0 {
                EmptyView()
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                        ForEach(0..<seg.count, id: \.self) { _ in
                            Circle()
                                .fill(seg.color.gradient)
                                .frame(width: 6, height: 6)
                                .shadow(color: .black.opacity(0.2), radius: 1)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: total)
                .accessibilityLabel(Text("Sex distribution: \(model.maleCount) boys, \(model.femaleCount) girls, \(model.lossCount) losses", bundle: .module))
            }
        }
    }
}

#if DEBUG
#Preview {
    DeliveryRowView(delivery: Delivery.sample())
        .frame(height: 80)
        .padding(.horizontal)
}
#endif
