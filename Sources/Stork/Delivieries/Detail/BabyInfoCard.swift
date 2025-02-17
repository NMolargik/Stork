//
//  BabyInfoCard.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct BabyInfoCard: View {
    @Environment(\.colorScheme) var colorScheme

    let baby: Baby
    let useMetric: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image("figure.child")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(baby.sex.color)
                .shadow(radius: 1)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading) {
                InfoRowView(
                    icon: Image("scalemass.fill"),
                    text: formattedWeight,
                    iconColor: Color("storkOrange")
                )
                
                InfoRowView(
                    icon: Image("ruler.fill"),
                    text: formattedHeight,
                    iconColor: Color.green
                )
                
                if baby.nurseCatch {
                    InfoRowView(
                        icon: Image("checkmark"),
                        text: "Nurse Catch",
                        iconColor: .teal
                    )
                }
                    
                if baby.nicuStay {
                    InfoRowView(
                        icon: Image("checkmark"),
                        text: "NICU Stay",
                        iconColor: .red
                    )
                }

            }
        }
        .padding()
        .backgroundCard(colorScheme: colorScheme)
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
    BabyInfoCard(baby: Baby(deliveryId: "123", nurseCatch: true, nicuStay: true, sex: Sex.male), useMetric: false)
}
