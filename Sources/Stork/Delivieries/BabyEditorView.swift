//
//  BabyEditorView.swift
//
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI
import StorkModel

struct BabyEditorView: View {
    @AppStorage("useMetric") private var useMetric: Bool = false
    
    @Environment(\.colorScheme) var colorScheme

    @Binding var baby: Baby

    @State private var weightInOunces: Double = 112.0 // Average weight
    @State private var lengthInInches: Double = 19.0 // Average length
    
    var babyNumber: Int
    var removeBaby: (String) -> Void
    
    // Constants for slider ranges
    let minWeightInOunces = 12.0 // 12 oz (~0.75 lbs)
    let maxWeightInOunces = 240.0 // 15 lbs in ounces (15 * 16 = 240 oz)
    let minLengthInInches = 8.0 // 8 inches
    let maxLengthInInches = 24.0 // 24 inches
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Baby \(babyNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        removeBaby(baby.id)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.black)
                        .padding(5)
                        .background(Circle().foregroundStyle(.white))
                }
            }
            
            Picker("Sex", selection: $baby.sex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.rawValue.capitalized).tag(sex)
                }
            }
            .pickerStyle(.segmented)
            
            VStack {
                Text("Weight: \(weightText)")
                    .font(.headline)
                    .foregroundStyle(.black)
                Slider(
                    value: $weightInOunces,
                    in: minWeightInOunces...maxWeightInOunces,
                    step: 1
                )
            }
            
            // Length Slider
            VStack {
                Text("Length: \(displayedLength)")
                    .font(.headline)
                    .foregroundStyle(.black)

                Slider(
                    value: $lengthInInches,
                    in: minLengthInInches...maxLengthInInches,
                    step: 0.1
                )
            }
            
            Toggle("Nurse Catch", isOn: $baby.nurseCatch)
                .foregroundStyle(.black)
                .fontWeight(.bold)
                .tint(.green)
        }
        .padding()
        .background(
            ZStack {
                Color.white
                baby.sex.color.opacity(0.4)
            }
        )
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    // Computed property to format weight as lbs and oz or kg
    private var weightText: String {
        if useMetric {
            let weightInKilograms = weightInOunces * 0.0283495 // 1 ounce = 0.0283495 kg
            return "\(String(format: "%.2f", weightInKilograms)) kg"
        } else {
            let pounds = Int(weightInOunces) / 16
            let ounces = Int(weightInOunces) % 16
            return "\(pounds) lbs \(ounces) oz"
        }
    }
    
    // Computed property to display length in inches or cm
    private var displayedLength: String {
        if useMetric {
            let centimeters = lengthInInches * 2.54 // 1 inch = 2.54 cm
            return "\(String(format: "%.1f", centimeters)) cm"
        } else {
            return "\(String(format: "%.1f", lengthInInches)) inches"
        }
    }
}

#Preview {
    BabyEditorView(
        baby: .constant(Baby(deliveryId: "", nurseCatch: true, sex: Sex.male)),
        babyNumber: 1,
        removeBaby: { _ in }
    )
}
