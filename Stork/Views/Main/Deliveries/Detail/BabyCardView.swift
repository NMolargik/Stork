//
//  BabyCardView.swift
//  Stork
//
//  Created by Nick Molargik on 11/2/25.
//

import SwiftUI

struct BabyCardView: View {
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    
    let baby: Baby
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header chip
            HStack(spacing: 8) {
                Image(systemName: "figure.child")
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                Text(baby.sex.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(baby.sex.color, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Baby \(index + 1): \(baby.sex.displayName)")

            // Measurement tiles
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                        Text("Length").bold()
                    }
                    Text(UnitConversion.heightDisplay(baby.height, useMetric: useMetricUnits))
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Length: \(UnitConversion.heightDisplay(baby.height, useMetric: useMetricUnits))")

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.storkOrange)
                            .accessibilityHidden(true)
                        Text("Weight").bold()
                    }
                    Text(UnitConversion.weightDisplay(baby.weight, useMetric: useMetricUnits))
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Weight: \(UnitConversion.weightDisplay(baby.weight, useMetric: useMetricUnits))")
            }

            // Meta rows as soft capsules (only when applicable)
            if baby.nurseCatch || baby.nicuStay {
                HStack(spacing: 8) {
                    if baby.nurseCatch {
                        Label("Nurse Catch", systemImage: "stethoscope")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(.red, in: Capsule())
                            .accessibilityLabel("Nurse catch")
                    }
                    if baby.nicuStay {
                        Label("NICU Stay", systemImage: "bed.double")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(.red, in: Capsule())
                            .accessibilityLabel("NICU stay required")
                    }
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
    }
}
