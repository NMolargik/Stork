//
//  BabyEditorView.swift
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI
import StorkModel

struct BabyEditorView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStorageManager: AppStorageManager

    @Binding var baby: Baby
    
    var babyNumber: Int
    var removeBaby: (String) -> Void
    var sampleMode: Bool = false

    // Internal state for weight and length
    @State private var pounds: Int
    @State private var ounces: Int
    @State private var lengthInCm: Double

    // MARK: - Constants
    private let ounceToKg = 0.0283495
    private let cmPerInch = 2.54

    private func ouncesToKg(_ ounces: Double) -> Double {
        return ounces * ounceToKg
    }

    private func kgToOunces(_ kg: Double) -> Double {
        return kg / ounceToKg
    }

    private func inchesToCm(_ inches: Double) -> Double {
        return inches * cmPerInch
    }

    private func cmToInches(_ cm: Double) -> Double {
        return cm / cmPerInch
    }

    private let weightRangeImperial: ClosedRange<Double> = 12.0...240.0 // 12 oz - 15 lbs
    private let weightRangeMetric: ClosedRange<Double> = 0.34...6.8     // 0.34 kg - 6.8 kg
    private let lengthRangeImperial: ClosedRange<Double> = 8.0...24.0   // Inches
    private let lengthRangeMetric: ClosedRange<Double> = 20.3...61.0    // Centimeters

    // MARK: - Initializer
    init(baby: Binding<Baby>, babyNumber: Int, removeBaby: @escaping (String) -> Void, sampleMode: Bool = false) {
        self._baby = baby
        self.babyNumber = babyNumber
        self.removeBaby = removeBaby
        self.sampleMode = sampleMode

        let initialBaby = sampleMode ? Baby(deliveryId: "", nurseCatch: false, nicuStay: false, sex: .male) : baby.wrappedValue
        self._pounds = State(initialValue: Int(initialBaby.weight) / 16) // Convert stored ounces to pounds
        self._ounces = State(initialValue: Int(initialBaby.weight) % 16) // Get remaining ounces
        self._lengthInCm = State(initialValue: initialBaby.height * cmPerInch) // Convert inches to cm
    }
    
    // MARK: - Body
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
                    .animation(.easeInOut(duration: 0.3), value: baby.sex)
            }
        )
        .cornerRadius(20)
        .shadow(radius: 2)
        .onChange(of: baby.weight) { _ in
            updateWeightFromModel()
        }
        .onChange(of: baby.height) { _ in
            updateHeightFromModel()
        }
        .onChange(of: appStorageManager.useMetric) { newMetric in
            updateUnits(toMetric: newMetric)
        }
    }

    // MARK: - UI Components
    private var headerSection: some View {
        HStack {
            Text("Baby \(babyNumber)")
                .font(.title2)
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .fontWeight(.bold)

            Spacer()

            if babyNumber > 1 && !sampleMode {
                Button {
                    HapticFeedback.trigger(style: .medium)
                    withAnimation {
                        removeBaby(baby.id)
                    }
                } label: {
                    Image("minus.symbol")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
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
        #if !SKIP
        .background {
            Rectangle()
                .cornerRadius(8)
                .foregroundStyle(Color("storkOrange"))
                .opacity(colorScheme == .dark ? 0.8 : 0.3)
        }
        #else
        .tint(Color("storkOrange"))
        #endif
        .onChange(of: baby.sex) { _ in HapticFeedback.trigger(style: .medium) }
    }
    
    private var weightStepper: some View {
        CustomStepperView(
            label: appStorageManager.useMetric
                ? "\(String(format: "%.2f", baby.weight * ounceToKg)) kg"  // ✅ Show 2 decimal places for kg
                : "\(pounds) lbs \(ounces) oz", // ✅ No decimal for lbs, separate ounces
            decrement: { adjustWeight(-1) },
            increment: { adjustWeight(1) },
            range: appStorageManager.useMetric ? weightRangeMetric : weightRangeImperial
        )
    }
    
    private var lengthStepper: some View {
        CustomStepperView(
            label: appStorageManager.useMetric
                ? "\(String(format: "%.1f", lengthInCm)) cm"   // ✅ Show 1 decimal place for cm
                : "\(String(format: "%.1f", baby.height)) in", // ✅ Show 1 decimal place for inches
            decrement: { adjustLength(-0.1) },
            increment: { adjustLength(0.1) },
            range: appStorageManager.useMetric ? lengthRangeMetric : lengthRangeImperial
        )
    }
    
    private var nurseCatchToggle: some View {
        CustomToggleView(isOn: $baby.nurseCatch, title: "Nurse Catch")
    }

    private var nicuToggle: some View {
        CustomToggleView(isOn: $baby.nicuStay, title: "NICU")
    }

    // MARK: - Helper Functions
    private func updateUnits(toMetric: Bool) {
        HapticFeedback.trigger(style: .medium)
        if toMetric {
            let weightKg = ouncesToKg(baby.weight).rounded()
            baby.weight = kgToOunces(weightKg)
            lengthInCm = inchesToCm(baby.height).rounded()
            baby.height = cmToInches(lengthInCm)
        } else {
            let weightOunces = kgToOunces(ouncesToKg(baby.weight)).rounded(.toNearestOrEven)
            baby.weight = weightOunces
            let heightInches = cmToInches(lengthInCm).rounded()
            baby.height = heightInches
            lengthInCm = inchesToCm(heightInches)
        }
    }
    
    private func adjustWeight(_ delta: Int) {
        HapticFeedback.trigger(style: .medium)
        
        if appStorageManager.useMetric {
            let newWeightKg = ouncesToKg(baby.weight) + (Double(delta) * 0.1)
            if weightRangeMetric.contains(newWeightKg) {
                baby.weight = max(kgToOunces(newWeightKg), 0.0)
            }
        } else {
            ounces += delta

            if ounces >= 16 {
                pounds += 1
                ounces -= 16
            } else if ounces < 0 {
                if pounds > 0 {
                    pounds -= 1
                    ounces += 16
                } else {
                    ounces = 0
                }
            }

            baby.weight = max(Double((pounds * 16) + ounces), 0.0)
        }
    }
    
    private func adjustLength(_ delta: Double) {
        HapticFeedback.trigger(style: .medium)
        if appStorageManager.useMetric {
            lengthInCm = max(lengthInCm + delta, 0.0)
        } else {
            lengthInCm = max(lengthInCm + (delta * cmPerInch), 0.0)
        }
        baby.height = cmToInches(lengthInCm)
    }
    
    private func updateWeightFromModel() {
        let totalOunces = Int(baby.weight)
        pounds = totalOunces / 16
        ounces = totalOunces % 16
    }

    private func updateHeightFromModel() {
        lengthInCm = baby.height * cmPerInch
    }
}

// MARK: - Sample Usage
#Preview {
    BabyEditorView(
        baby: .constant(Baby(deliveryId: "", nurseCatch: true, nicuStay: false, sex: .male)),
        babyNumber: 1,
        removeBaby: { _ in },
        sampleMode: true
    )
    .padding()
    .environmentObject(AppStorageManager())
}


