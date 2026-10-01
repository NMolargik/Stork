//
//  QuickEntryView.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import StorkCore
import StorkDesignSystem
import WatchKit
import os

struct QuickEntryView: View {
    let model: WatchDeliveryModel

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
                        .accessibilityHidden(true)
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
        do {
            // The use-case runs the shared save side effects (app-group counts,
            // complication reloads) and returns real milestone detection.
            let result = try model.log(
                boys: boyCount,
                girls: girlCount,
                losses: lossCount,
                method: deliveryMethod
            )
            savedDelivery = result.delivery
            showingConfirmation = true

            if result.milestone != nil {
                WatchHaptics.milestone()
            } else {
                WatchHaptics.success()
            }
        } catch {
            Log.deliveries.error("Failed to save delivery: \(error.localizedDescription)")
            WatchHaptics.error()
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

    /// Singular, lowercased form of the row label for button accessibility labels.
    private var singularLabel: String {
        switch label {
        case "Boys": return "boy"
        case "Girls": return "girl"
        default: return label.lowercased()
        }
    }

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityHidden(true)

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
                .accessibilityLabel("Remove \(singularLabel)")

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
                .accessibilityLabel("Add \(singularLabel)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(count)")
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
                .accessibilityHidden(true)

            Text("Saved!")
                .font(.headline)

            if let delivery = delivery {
                Text("^[\(delivery.babyCount) baby](inflect: true)")
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

#if DEBUG
private struct PreviewLoadDeliveries: LoadDeliveries {
    func callAsFunction() throws(PersistenceError) -> [Delivery] { [] }
}

private struct PreviewLogDelivery: LogDelivery {
    @discardableResult
    func callAsFunction(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration? { nil }
}

#Preview {
    QuickEntryView(model: WatchDeliveryModel(
        loadDeliveries: PreviewLoadDeliveries(),
        logDelivery: PreviewLogDelivery()
    ))
}
#endif
