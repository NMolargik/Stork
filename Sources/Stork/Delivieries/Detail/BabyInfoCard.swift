//
//  BabyInfoCard.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct BabyInfoCard: View {
    let baby: Baby
    let useMetric: Bool

    var body: some View {
        HStack {
            Image(systemName: "figure.child")
                .foregroundStyle(baby.sex.color)
                .font(.title)
                .frame(width: 30)
                .shadow(radius: 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                InfoRowView(
                    icon: Image(systemName: "scalemass.fill"),
                    text: formattedWeight,
                    iconColor: .orange
                )

                InfoRowView(
                    icon: Image(systemName: "ruler.fill"),
                    text: formattedHeight,
                    iconColor: .green
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if baby.nurseCatch {
                Text("Nurse Catch")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .accessibilityLabel("Nurse Catch")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 2).opacity(0.9))
        .padding(.horizontal)
    }

    // MARK: - Computed Properties for Weight & Height
    private var formattedWeight: String {
        useMetric ? "\(String(format: "%.2f", baby.weight * 0.0283495)) kg" :
            "\(Int(baby.weight) / 16) lbs \(Int(baby.weight) % 16) oz"
    }

    private var formattedHeight: String {
        useMetric ? "\(String(format: "%.1f", baby.height * 2.54)) cm" :
            "\(String(format: "%.1f", baby.height)) inches"
    }
}

#Preview {
    BabyInfoCard(baby: Baby(deliveryId: "123", nurseCatch: true, sex: Sex.male), useMetric: false)
}
