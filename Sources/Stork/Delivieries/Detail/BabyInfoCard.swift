//
//  BabyInfoCard.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct BabyInfoCard: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false

    let baby: Baby
    let useMetric: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image("figure.child", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(baby.sex.color)
                .shadow(radius: 1)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading) {
                infoRows
            }
        }
        .padding()
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
    }

    // MARK: - Computed Properties for Weight & Height
    private var infoRows: some View {
        Group {
            InfoRowView(
                icon: Image("scalemass.fill", bundle: .module),
                text: formattedWeight,
                iconColor: Color("storkOrange")
            )
            
            InfoRowView(
                icon: Image("ruler.fill", bundle: .module),
                text: formattedHeight,
                iconColor: Color.green
            )
            
            if baby.nurseCatch || baby.nicuStay {
                InfoRowView(
                    icon: Image("checkmark_stork", bundle: .module),
                    text: baby.nurseCatch ? "Nurse Catch" : "NICU Stay",
                    iconColor: baby.nurseCatch ? Color.teal : Color.red
                )
            }
        }
    }

    private var formattedWeight: String {
        formatWeight(weight: baby.weight)
    }

    private var formattedHeight: String {
        formatHeight(height: baby.height)
    }
    
    // MARK: - Helper Methods
    private func formatWeight(weight: Double) -> String {
        useMetric ? "\(String(format: "%.2f", weight * 0.0283495)) kg" :
            "\(Int(weight) / 16) lbs \(Int(weight) % 16) oz"
    }
    
    private func formatHeight(height: Double) -> String {
        useMetric ? "\(String(format: "%.1f", height * 2.54)) cm" :
            "\(String(format: "%.1f", height)) inches"
    }
}

#Preview {
    BabyInfoCard(baby: Baby(deliveryId: "123", nurseCatch: true, nicuStay: true, sex: Sex.male), useMetric: false)
}
