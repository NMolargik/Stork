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
    @State private var weightInOunces: Double = 112.0 // Default
    @State private var lengthInInches: Double = 19.0   // Default

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
        VStack(alignment: .center, spacing: 10) {
            headerSection
            
            // MARK: - Sex Picker
            Picker("Sex", selection: $baby.sex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.rawValue.capitalized).tag(sex)
                }
            }
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .pickerStyle(.segmented)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black.opacity(0.8) : .clear)
                    .cornerRadius(8)
            }
            .onChange(of: baby.sex) { _ in
                triggerHaptic()
            }
            
            // MARK: - Weight
            if useMetric {
                // -----------------------------------------------------------
                // CUSTOM STEPPER: Metric Weight (kg) in 0.1 increments
                // -----------------------------------------------------------
                HStack(spacing: 20) {
                    
                    // Minus Button
                    Button {
                        triggerHaptic()
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
                        triggerHaptic()
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
                        .cornerRadius(20)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.horizontal)
                
            } else {
                // -----------------------------------------------------------
                // CUSTOM STEPPERS: Imperial Weight (lbs + oz)
                // -----------------------------------------------------------
                HStack(spacing: 2) {
                    Button {
                        triggerHaptic()
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
                        triggerHaptic()
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
                    
                    Spacer()
                    
                // --- Ounces Stepper ---
                    Button {
                        triggerHaptic()
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
                        triggerHaptic()
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
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(20)
                        .foregroundStyle(Color.white.opacity(0.8))
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
                        triggerHaptic()
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
                        triggerHaptic()
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
                        .cornerRadius(20)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                
            } else {
                // -----------------------------------------------------------
                // CUSTOM STEPPER: Imperial Length (inches)
                // -----------------------------------------------------------
                HStack(spacing: 10) {
                    // Minus
                    Button {
                        triggerHaptic()
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
                        triggerHaptic()
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
                        .cornerRadius(20)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            
            
            Toggle("Nurse Catch", isOn: $baby.nurseCatch)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .tint(.green)
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(20)
                        .foregroundStyle(Color.white.opacity(0.8))
                }
        }
        .padding()
        .background(
            ZStack {
                Color.white
                baby.sex.color.opacity(0.4)
            }
        )
        .cornerRadius(20)
        .shadow(radius: 2)
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
                    triggerHaptic()
                    withAnimation {
                        removeBaby(baby.id)
                    }
                }) {
                    Image(systemName: "minus")
                        .fontWeight(.bold)
                        .padding(10)
                        .foregroundStyle(.white)
                        .background(Circle().foregroundStyle(.red))
                }
            }
        }
        .frame(height: 40)
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
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
        babyNumber: 2,
        removeBaby: { _ in }
    )
    .padding()
}
