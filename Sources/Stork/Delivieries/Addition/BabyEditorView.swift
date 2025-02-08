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
    
    // MARK: - Properties
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
        .onChange(of: useMetric) { newMetric in
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
                    triggerHaptic()
                    withAnimation {
                        removeBaby(baby.id)
                    }
                } label: {
                    Image("minus")
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
        .background {
            Rectangle()
                .cornerRadius(8)
                .foregroundStyle(Color("storkOrange"))
                .opacity(colorScheme == .dark ? 0.8 : 0.3)
        }
        .onChange(of: baby.sex) { _ in triggerHaptic() }
    }
    
    private var weightStepper: some View {
        StepperView(
            label: useMetric
                ? "\(String(format: "%.2f", baby.weight * ounceToKg)) kg"  // ✅ Show 2 decimal places for kg
                : "\(pounds) lbs \(ounces) oz", // ✅ No decimal for lbs, separate ounces
            decrement: { adjustWeight(-1) },
            increment: { adjustWeight(1) },
            range: useMetric ? weightRangeMetric : weightRangeImperial
        )
    }
    
    private var lengthStepper: some View {
        StepperView(
            label: useMetric
                ? "\(String(format: "%.1f", lengthInCm)) cm"   // ✅ Show 1 decimal place for cm
                : "\(String(format: "%.1f", baby.height)) in", // ✅ Show 1 decimal place for inches
            decrement: { adjustLength(-0.1) },
            increment: { adjustLength(0.1) },
            range: useMetric ? lengthRangeMetric : lengthRangeImperial
        )
    }
    
    private var nurseCatchToggle: some View {
        CustomToggle(isOn: $baby.nurseCatch, title: "Nurse Catch")
    }

    private var nicuToggle: some View {
        CustomToggle(isOn: $baby.nicuStay, title: "NICU")
    }

    // MARK: - Helper Functions
    private func updateUnits(toMetric: Bool) {
        triggerHaptic()

        if toMetric {
            // Convert ounces to kilograms and round to the nearest kg
            let weightKg = (baby.weight * ounceToKg).rounded()
            baby.weight = weightKg / ounceToKg // Convert back to ounces for storage

            // Convert inches to centimeters and round to the nearest cm
            lengthInCm = (baby.height * cmPerInch).rounded()
            baby.height = lengthInCm / cmPerInch // Convert back to inches for storage
        } else {
            // Convert kilograms to ounces and round to the nearest full ounce
            let weightOunces = (baby.weight * ounceToKg).rounded(.toNearestOrEven)
            baby.weight = weightOunces

            // Convert centimeters to inches and round to the nearest inch
            let heightInches = (lengthInCm / cmPerInch).rounded()
            baby.height = heightInches
            lengthInCm = heightInches * cmPerInch // Convert back to cm for display
        }

        print("🔄 Units switched. Weight: \(baby.weight) oz, Length: \(baby.height) in")
    }
    
    private func adjustWeight(_ delta: Int) {
        triggerHaptic()
        
        if useMetric {
            let newWeightKg = (baby.weight * ounceToKg) + (Double(delta) * 0.1) // ✅ Increment by 0.1 kg
            let newWeightOunces = newWeightKg / ounceToKg // Convert back to ounces

            print("📏 Metric Mode - Proposed Weight: \(newWeightKg) kg (\(newWeightOunces) oz)")

            if weightRangeMetric.contains(newWeightKg) {
                baby.weight = newWeightOunces // ✅ Save weight as ounces
                print("✅ Metric Mode: Updated baby.weight to \(baby.weight) oz (\(newWeightKg) kg)")
            } else {
                print("❌ Metric Mode: \(newWeightKg) kg is OUT OF RANGE")
            }
        } else {
            ounces += delta

            if ounces >= 16 {
                pounds += 1
                ounces -= 16
            } else if ounces < 0 {
                pounds -= 1
                ounces += 16
            }

            baby.weight = Double((pounds * 16) + ounces)
            print("✅ Imperial Mode: Updated baby.weight to \(baby.weight) oz")
        }
    }
    
    private func adjustLength(_ delta: Double) {
        triggerHaptic()

        if useMetric {
            lengthInCm += delta // ✅ Adjust by 0.1 cm
        } else {
            lengthInCm += delta * cmPerInch // ✅ Adjust by 0.1 inches
        }

        baby.height = lengthInCm / cmPerInch // ✅ Always store height in inches
        print("📏 Length Updated: \(lengthInCm) cm (\(baby.height) in)")
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
}

import SwiftUI

/// A custom toggle view that displays a title and a sliding circle indicator.
struct CustomToggle: View {
    @Binding var isOn: Bool
    var title: String
    var onColor: Color = .green
    var offColor: Color = Color.gray.opacity(0.2)
    var textColor: Color = .black

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOn = !isOn
                triggerHaptic()
            }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(textColor)
                    .fontWeight(.bold)
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    // Background for the toggle "track"
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isOn ? onColor : offColor)
                        .frame(width: 50, height: 30)
                    // The sliding "thumb"
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .padding(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
            )
        }
    }
}
