//
//  BabyRowView.swift
//  StorkFeatureDeliveries
//
//  A baby summary row inside the entry form, with edit and (animated) delete actions.
//

import SwiftUI
import StorkCore
import StorkDesignSystem

struct BabyRowView: View {
    let baby: Baby
    let useMetricUnits: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isDeleting = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundColor(baby.sex.color)
                .font(.system(size: 24))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(baby.sex.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(UnitConversion.weightHeightSummary(weightOunces: baby.weight, heightInches: baby.height, useMetric: useMetricUnits))
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    if baby.nicuStay {
                        Image(systemName: "cross.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.storkOrange)
                            .accessibilityLabel(Text("NICU stay", bundle: .module))
                    }
                    if baby.nurseCatch {
                        Image(systemName: "person.2.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .accessibilityLabel(Text("Nurse catch", bundle: .module))
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .accessibilityLabel(Text("Edit baby", bundle: .module))

                Button {
                    guard !isDeleting else { return }
                    withAnimation(.easeInOut(duration: 0.18)) { isDeleting = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDelete() }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .padding(8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .accessibilityLabel(Text("Delete baby", bundle: .module))
            }
        }
        .padding()
        .opacity(isDeleting ? 0 : 1)
        .offset(x: isDeleting ? 20 : 0)
        .scaleEffect(isDeleting ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.18), value: isDeleting)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(baby.sex.displayName) baby, \(UnitConversion.weightHeightSummary(weightOunces: baby.weight, heightInches: baby.height, useMetric: useMetricUnits))\(baby.nicuStay ? ", NICU stay" : "")\(baby.nurseCatch ? ", nurse catch" : "")")
    }
}

#if DEBUG
#Preview("Imperial Units") {
    BabyRowView(baby: Baby.sample(), useMetricUnits: false, onEdit: {}, onDelete: {})
}
#endif
