//
//  QuickEntryView.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData
import WatchKit

struct QuickEntryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var boyCount: Int = 0
    @State private var girlCount: Int = 0
    @State private var lossCount: Int = 0
    @State private var deliveryMethod: DeliveryMethod = .vaginal
    @State private var showingConfirmation: Bool = false
    @State private var savedDelivery: Delivery?

    private var totalBabies: Int {
        boyCount + girlCount + lossCount
    }

    private var canSave: Bool {
        totalBabies > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.storkBlue)
                    Text("Quick Entry")
                        .font(.headline)
                }

                // Boy stepper
                StepperRow(
                    label: "Boys",
                    count: $boyCount,
                    color: .storkBlue,
                    systemImage: "figure.child"
                )

                // Girl stepper
                StepperRow(
                    label: "Girls",
                    count: $girlCount,
                    color: .storkPink,
                    systemImage: "figure.child"
                )

                // Loss stepper
                StepperRow(
                    label: "Loss",
                    count: $lossCount,
                    color: .storkPurple,
                    systemImage: "heart.slash"
                )

                Divider()

                // Delivery method picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Method")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Method", selection: $deliveryMethod) {
                        ForEach(DeliveryMethod.allCases, id: \.self) { method in
                            Text(method.description).tag(method)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 50)
                }

                // Save button
                Button {
                    saveDelivery()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.storkBlue)
                .disabled(!canSave)

                if !canSave {
                    Text("Add at least one baby")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingConfirmation) {
            ConfirmationView(delivery: savedDelivery) {
                showingConfirmation = false
                resetForm()
            }
        }
    }

    private func saveDelivery() {
        // Create babies based on counts
        var babies: [Baby] = []

        for _ in 0..<boyCount {
            let baby = Baby(sex: .male)
            babies.append(baby)
        }
        for _ in 0..<girlCount {
            let baby = Baby(sex: .female)
            babies.append(baby)
        }
        for _ in 0..<lossCount {
            let baby = Baby(sex: .loss)
            babies.append(baby)
        }

        // Create delivery
        let delivery = Delivery(
            date: Date(),
            babies: babies,
            babyCount: totalBabies,
            deliveryMethod: deliveryMethod,
            epiduralUsed: false,
            notes: "Added from Watch - may lack baby details."
        )

        // Link babies to delivery
        for baby in babies {
            baby.delivery = delivery
        }

        // Save
        modelContext.insert(delivery)
        do {
            try modelContext.save()
            savedDelivery = delivery
            showingConfirmation = true

            // Haptic feedback for milestone check
            WatchHaptics.success()

            // Check for milestone
            checkMilestone()
        } catch {
            print("Failed to save delivery: \(error)")
            WatchHaptics.error()
        }
    }

    private func checkMilestone() {
        // Query total babies
        let descriptor = FetchDescriptor<Baby>()
        if let allBabies = try? modelContext.fetch(descriptor) {
            let total = allBabies.count
            let milestones = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]
            if milestones.contains(total) {
                WatchHaptics.milestone()
            }
        }
    }

    private func resetForm() {
        boyCount = 0
        girlCount = 0
        lossCount = 0
        deliveryMethod = .vaginal
        savedDelivery = nil
    }
}

// MARK: - Stepper Row
struct StepperRow: View {
    let label: String
    @Binding var count: Int
    let color: Color
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if count > 0 {
                        count -= 1
                        WatchHaptics.lightImpact()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(count > 0 ? color : .gray)
                }
                .buttonStyle(.plain)
                .disabled(count == 0)

                Text("\(count)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .frame(minWidth: 20)

                Button {
                    if count < 10 {
                        count += 1
                        WatchHaptics.lightImpact()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Confirmation View
struct ConfirmationView: View {
    let delivery: Delivery?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Saved!")
                .font(.headline)

            if let delivery = delivery {
                Text("\(delivery.babyCount) \(delivery.babyCount == 1 ? "baby" : "babies")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Edit details on your iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    QuickEntryView()
}
