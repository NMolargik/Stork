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

    private func weightDisplay(_ ounces: Double) -> String {
        if useMetricUnits {
            let grams = ounces * 28.349523125
            return "\(Int(round(grams))) g"
        } else {
            return String(format: "%.1f oz", ounces)
        }
    }

    private func heightDisplay(_ inches: Double) -> String {
        if useMetricUnits {
            let cm = inches * 2.54
            return String(format: "%.1f cm", cm)
        } else {
            return String(format: "%.1f in", inches)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header chip
            HStack(spacing: 8) {
                Image(systemName: "figure.child")
                    .foregroundStyle(.white)
                Text(baby.sex.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(baby.sex.color, in: Capsule())

            // Measurement tiles
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler")
                            .foregroundStyle(.green)
                        Text("Length").bold()
                    }
                    Text(heightDisplay(baby.height))
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.storkOrange)
                        Text("Weight").bold()
                    }
                    Text(weightDisplay(baby.weight))
                        .font(.headline)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                )
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
                    }
                    if baby.nicuStay {
                        Label("NICU Stay", systemImage: "bed.double")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(.red, in: Capsule())
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
