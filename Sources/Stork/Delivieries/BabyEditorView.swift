//
//  BabyEditorView.swift
//
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI
import StorkModel

struct BabyEditorView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("useMetric") private var useMetric: Bool = false
    
    @Binding var baby: Baby
    
    // Internally store weight in ounces and length in inches
    @State private var weightInOunces: Double = 112.0 // Default/initial
    @State private var lengthInInches: Double = 19.0   // Default/initial

    var babyNumber: Int
    var removeBaby: (String) -> Void
    
    // MARK: - Constants
    
    // Imperial
    let minWeightInOunces = 12.0   // 12 oz (~0.75 lbs)
    let maxWeightInOunces = 240.0  // 15 lbs in ounces
    let minLengthInInches = 8.0
    let maxLengthInInches = 24.0
    
    // Metric (approx)
    let minWeightInKg = 0.34
    let maxWeightInKg = 6.8
    let minLengthInCm = 20.3
    let maxLengthInCm = 61.0
    
    // Conversion
    private let ounceToKg = 0.0283495  // 1 oz = ~0.0283495 kg
    private let cmPerInch = 2.54       // 1 in = 2.54 cm
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            headerSection
            
            // MARK: - Sex Picker
            Picker("Sex", selection: $baby.sex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.rawValue.capitalized).tag(sex)
                }
            }
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .pickerStyle(.segmented)
            .padding(5)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black : .clear)
                    .cornerRadius(10)
            }
            
            // MARK: - Weight
            if useMetric {
                // -----------------------------------------------------------
                // CUSTOM STEPPER: Metric Weight (kg) in 0.1 increments
                // -----------------------------------------------------------
                HStack(spacing: 20) {
                    
                    // Minus Button
                    Button {
                        let newKg = weightInKg - 0.1
                        if newKg >= minWeightInKg {
                            weightInOunces = newKg / ounceToKg
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)

                    }
                    
                    // Display
                    Text("\(String(format: "%.2f", weightInKg)) kg")
                        .frame(minWidth: 70)
                        .font(.title3)
                        .foregroundStyle(Color.black)
                        .fontWeight(.semibold)
                    
                    // Plus Button
                    Button {
                        let newKg = weightInKg + 0.1
                        if newKg <= maxWeightInKg {
                            weightInOunces = newKg / ounceToKg
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)

                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(Color.white)
                }
                
            } else {
                // -----------------------------------------------------------
                // CUSTOM STEPPERS: Imperial Weight (lbs + oz)
                // -----------------------------------------------------------
                HStack {
                    // --- Pounds Stepper ---
                    HStack(spacing: 4) {
                        Button {
                            let newPounds = pounds - 1
                            // Convert that to total ounces
                            let total = Double(newPounds * 16 + ounces)
                            // Check bounds
                            if newPounds >= 0, total >= minWeightInOunces {
                                weightInOunces = total
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.black)
                        }
                        
                        Text("\(pounds) lbs")
                            .frame(minWidth: 60)
                            .font(.title3)
                            .foregroundStyle(Color.black)
                            .fontWeight(.semibold)

                        
                        Button {
                            let newPounds = pounds + 1
                            let total = Double(newPounds * 16 + ounces)
                            if total <= maxWeightInOunces {
                                weightInOunces = total
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.black)
                        }
                    }
                    
                    Spacer().frame(width: 20)
                    
                    // --- Ounces Stepper ---
                    HStack(spacing: 4) {
                        Button {
                            let newOunces = ounces - 1
                            let total = Double(pounds * 16 + newOunces)
                            if newOunces >= 0, total >= minWeightInOunces {
                                weightInOunces = total
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.black)
                        }
                        
                        Text("\(ounces) oz")
                            .frame(minWidth: 50)
                            .font(.title3)
                            .foregroundStyle(Color.black)
                            .fontWeight(.semibold)
                        
                        Button {
                            let newOunces = ounces + 1
                            let total = Double(pounds * 16 + newOunces)
                            // Don’t exceed 15 oz (since 16 oz = 1 lb)
                            if newOunces <= 15, total <= maxWeightInOunces {
                                weightInOunces = total
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.black)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(Color.white)
                }
            }
            
            // MARK: - Length
            if useMetric {
                // -----------------------------------------------------------
                // CUSTOM STEPPER: Metric Length (cm)
                // -----------------------------------------------------------
                HStack(spacing: 20) {
                    // Minus
                    Button {
                        let newCm = lengthInCm - 0.1
                        if newCm >= minLengthInCm {
                            lengthInInches = newCm / cmPerInch
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)
                    }
                    
                    Text("\(String(format: "%.1f", lengthInCm)) cm")
                        .frame(minWidth: 70)
                        .font(.title3)
                        .foregroundStyle(Color.black)
                        .fontWeight(.semibold)
                    
                    // Plus
                    Button {
                        let newCm = lengthInCm + 0.1
                        if newCm <= maxLengthInCm {
                            lengthInInches = newCm / cmPerInch
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(Color.white)
                }
                
            } else {
                // -----------------------------------------------------------
                // CUSTOM STEPPER: Imperial Length (inches)
                // -----------------------------------------------------------
                HStack(spacing: 20) {
                    // Minus
                    Button {
                        let newValue = lengthInInches - 0.1
                        if newValue >= minLengthInInches {
                            lengthInInches = newValue
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)
                    }
                    
                    Text("\(String(format: "%.1f", lengthInInches)) in")
                        .frame(minWidth: 70)
                        .font(.title3)
                        .foregroundStyle(Color.black)
                        .fontWeight(.semibold)
                    
                    // Plus
                    Button {
                        let newValue = lengthInInches + 0.1
                        if newValue <= maxLengthInInches {
                            lengthInInches = newValue
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(Color.white)
                }
            }
            
            Toggle("Nurse Catch", isOn: $baby.nurseCatch)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? .black : .white)
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
    
    // MARK: - Header (Trash Button)
    private var headerSection: some View {
        HStack {
            Text("Baby \(babyNumber)")
                .font(.title2)
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .fontWeight(.bold)
            
            Spacer()
            
            if (babyNumber > 1) {
                Button(action: {
                    withAnimation {
                        removeBaby(baby.id)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .padding(10)
                        .foregroundStyle(.orange)
                        .background(Circle().foregroundStyle(colorScheme == .dark ? .black : .white))
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current weight in kg (derived from ounces)
    private var weightInKg: Double {
        weightInOunces * ounceToKg
    }
    
    /// Extract pounds from total ounces (integer division)
    private var pounds: Int {
        Int(weightInOunces) / 16
    }
    
    /// Extract remainder ounces from total ounces
    private var ounces: Int {
        Int(weightInOunces) % 16
    }
    
    /// Display text for weight
    private var weightText: String {
        if useMetric {
            return "\(String(format: "%.2f", weightInKg)) kg"
        } else {
            return "\(pounds) lbs \(ounces) oz"
        }
    }
    
    /// Computed length in cm (derived from inches)
    private var lengthInCm: Double {
        lengthInInches * cmPerInch
    }
    
    /// Display text for length
    private var displayedLength: String {
        if useMetric {
            return "\(String(format: "%.1f", lengthInCm)) cm"
        } else {
            return "\(String(format: "%.1f", lengthInInches)) inches"
        }
    }
}

// MARK: - Preview

#Preview {
    BabyEditorView(
        baby: .constant(Baby(deliveryId: "", nurseCatch: true, sex: .male)),
        babyNumber: 1,
        removeBaby: { _ in }
    )
}
