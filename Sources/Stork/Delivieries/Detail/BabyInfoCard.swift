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
        VStack {
            HStack(spacing: 10) {
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(baby.sex.color)
                    .shadow(radius: 1)
                    .accessibilityHidden(true)
                
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

            }

            if (baby.nurseCatch || baby.nicuStay) {
                HStack(spacing: 30) {
                    if baby.nurseCatch {
                        Text("Nurse Catch")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .accessibilityLabel("Nurse Catch")
                            .padding(5)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 2)
                            }
                    }
                    
                    if baby.nicuStay {
                        Text("NICU")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .accessibilityLabel("NICU")
                            .padding(5)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 2)
                            }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .backgroundCard(colorScheme: colorScheme)
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
    BabyInfoCard(baby: Baby(deliveryId: "123", nurseCatch: true, nicuStay: true, sex: Sex.male), useMetric: false)
}
