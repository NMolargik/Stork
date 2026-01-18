//
//  BabyRowView.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI

struct BabyRowView: View {
    let baby: Baby
    let useMetricUnits: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isDeleting: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(baby.sex.color)
                    .font(.system(size: 24))
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(baby.sex.rawValue.capitalized)
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
                                .accessibilityLabel("NICU stay")
                        }
                        if baby.nurseCatch {
                            Image(systemName: "person.2.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .accessibilityLabel("Nurse catch")
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
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isDeleting)
                    .accessibilityLabel("Edit baby")
                    .accessibilityHint("Opens form to edit this baby's information")

                    Button(action: {
                        guard !isDeleting else { return }
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isDeleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .padding(8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isDeleting)
                    .accessibilityLabel("Delete baby")
                    .accessibilityHint("Removes this baby from the delivery")
                }
            }
            .padding()
        }
        .opacity(isDeleting ? 0 : 1)
        .offset(x: isDeleting ? 20 : 0)
        .scaleEffect(isDeleting ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.18), value: isDeleting)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(baby.sex.rawValue.capitalized) baby, \(UnitConversion.weightHeightSummary(weightOunces: baby.weight, heightInches: baby.height, useMetric: useMetricUnits))\(baby.nicuStay ? ", NICU stay" : "")\(baby.nurseCatch ? ", nurse catch" : "")")
    }
}

#Preview("Imperial Units") {
    BabyRowView(
        baby: Baby.sample,
        useMetricUnits: false,
        onEdit: {},
        onDelete: {}
    )
}
