//
//  BabyEditorView.swift
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
    @State private var weightInOunces: Double
    @State private var lengthInInches: Double

    var babyNumber: Int
    var removeBaby: (String) -> Void

    // MARK: - Constants
    private let ounceToKg = 0.0283495
    private let cmPerInch = 2.54

    private let weightRangeImperial: ClosedRange<Double> = 12.0...240.0 // 12 oz - 15 lbs
    private let weightRangeMetric: ClosedRange<Double> = 0.34...6.8     // 0.34 kg - 6.8 kg
    private let lengthRangeImperial: ClosedRange<Double> = 8.0...24.0   // Inches
    private let lengthRangeMetric: ClosedRange<Double> = 20.3...61.0    // Centimeters

    init(baby: Binding<Baby>, babyNumber: Int, removeBaby: @escaping (String) -> Void) {
        self._baby = baby
        self.babyNumber = babyNumber
        self.removeBaby = removeBaby
        self._weightInOunces = State(initialValue: baby.wrappedValue.weight)
        self._lengthInInches = State(initialValue: baby.wrappedValue.height)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            headerSection
            sexPicker
            weightStepper
            lengthStepper
            nurseCatchToggle
            nicuToggle 
        }
        .padding()
        .background(
            ZStack {
                Color.white
                baby.sex.color.opacity(0.4)
                    .animation(.easeInOut(duration: 0.3), value: baby.sex) // Animate background color change
            }
        )
        .cornerRadius(20)
        .shadow(radius: 2)
        .onChange(of: weightInOunces) { baby.weight = $0 }
        .onChange(of: lengthInInches) { baby.height = $0 }
    }

    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack {
            Text("Baby \(babyNumber)")
                .font(.title2)
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .fontWeight(.bold)

            Spacer()

            if babyNumber > 1 {
                Button {
                    triggerHaptic()
                    withAnimation { removeBaby(baby.id) }
                } label: {
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

    private var sexPicker: some View {
        Picker("Sex", selection: $baby.sex) {
            ForEach(Sex.allCases, id: \.self) {
                Text($0.rawValue.capitalized).tag($0)
            }
        }
        .foregroundStyle(colorScheme == .dark ? .black : .white)
        .pickerStyle(.segmented)
        .background {
            Rectangle()
                .cornerRadius(8)
                .foregroundStyle(.indigo)
                .opacity(colorScheme == .dark ? 0.8 : 0.3)
        }
        .onChange(of: baby.sex) { _ in triggerHaptic() }
    }
    
    private var weightStepper: some View {
        StepperView(
            label: useMetric ? "\(String(format: "%.2f", weightInKg)) kg" : "\(pounds) lbs \(ounces) oz",
            decrement: { adjustWeight(-0.1) },
            increment: { adjustWeight(0.1) },
            range: useMetric ? weightRangeMetric : weightRangeImperial
        )    }
    
    private var lengthStepper: some View {
        StepperView(
            label: useMetric ? "\(String(format: "%.1f", lengthInCm)) cm" : "\(String(format: "%.1f", lengthInInches)) in",
            decrement: { adjustLength(-0.1) },
            increment: { adjustLength(0.1) },
            range: useMetric ? lengthRangeMetric : lengthRangeImperial
        )
    }
    
    private var nurseCatchToggle: some View {
        Toggle("Nurse Catch", isOn: $baby.nurseCatch)
            .fontWeight(.bold)
            .foregroundStyle(.black)
            .tint(.green)
            .padding()
            .background(
                Rectangle()
                    .foregroundStyle(Color.white.opacity(0.8))
                    .overlay(baby.nurseCatch ? Color.green.opacity(0.2) : Color.clear)
                    .animation(.easeInOut(duration: 0.3), value: baby.nurseCatch) // Animate color change
                    .cornerRadius(20)
            )
    }

    private var nicuToggle: some View {
        Toggle("NICU", isOn: $baby.nicuStay)
            .fontWeight(.bold)
            .foregroundStyle(.black)
            .tint(.green)
            .padding()
            .background(
                Rectangle()
                    .foregroundStyle(Color.white.opacity(0.8))
                    .overlay(baby.nicuStay ? Color.green.opacity(0.2) : Color.clear)
                    .animation(.easeInOut(duration: 0.3), value: baby.nicuStay) // Animate color change
                    .cornerRadius(20)
            )
    }

    // MARK: - Computed Properties
    
    private var weightInKg: Double { weightInOunces * ounceToKg }
    private var pounds: Int { Int(weightInOunces) / 16 }
    private var ounces: Int { Int(weightInOunces) % 16 }
    private var lengthInCm: Double { lengthInInches * cmPerInch }

    // MARK: - Helper Functions
    
    private func adjustWeight(_ delta: Double) {
        triggerHaptic()
        let newWeight = useMetric ? weightInKg + delta : weightInOunces + (delta * 16)
        if weightRangeImperial.contains(newWeight * (useMetric ? 1.0 / ounceToKg : 1.0)) {
            weightInOunces = newWeight * (useMetric ? 1.0 / ounceToKg : 1.0)
        }
    }

    private func adjustLength(_ delta: Double) {
        triggerHaptic()
        let newLength = useMetric ? lengthInCm + delta : lengthInInches + delta
        if lengthRangeImperial.contains(newLength * (useMetric ? 1.0 / cmPerInch : 1.0)) {
            lengthInInches = newLength * (useMetric ? 1.0 / cmPerInch : 1.0)
        }
    }
}

// MARK: - Preview

#Preview {
    BabyEditorView(
        baby: .constant(Baby(deliveryId: "", nurseCatch: true, nicuStay: false, sex: .male)),
        babyNumber: 2,
        removeBaby: { _ in }
    )
    .padding()
}
