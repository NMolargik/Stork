//
//  LogDeliveryIntent.swift
//  Stork
//
//  Lets Siri / Shortcuts / Apple Intelligence log a delivery without
//  opening the app — counts only, never patient-identifying data.
//

import AppIntents
import Foundation
import os

struct LogDeliveryIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Delivery"
    static let description = IntentDescription(
        "Quickly log a delivery you performed. You can add details like measurements later in Stork.",
        categoryName: "Deliveries"
    )

    @Parameter(title: "Boys", default: 0, inclusiveRange: (0, 10))
    var boys: Int

    @Parameter(title: "Girls", default: 0, inclusiveRange: (0, 10))
    var girls: Int

    @Parameter(title: "Losses", default: 0, inclusiveRange: (0, 10))
    var losses: Int

    @Parameter(title: "Delivery Method", default: .vaginal)
    var method: DeliveryMethod

    @Parameter(title: "Epidural Used", default: false)
    var epiduralUsed: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$method) delivery with \(\.$boys) boys and \(\.$girls) girls") {
            \.$losses
            \.$epiduralUsed
        }
    }

    @Dependency
    private var deliveryManager: DeliveryManager

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // "Log a delivery" with no counts shouldn't fail — ask for them.
        // Parameterized invocations ("…with two girls") skip these prompts.
        var boys = self.boys
        var girls = self.girls
        if boys + girls + losses == 0 {
            boys = try await $boys.requestValue("How many boys?")
            girls = try await $girls.requestValue("And how many girls?")
        }

        let total = boys + girls + losses
        guard total > 0 else {
            return .result(dialog: "Nothing logged — a delivery needs at least one baby.")
        }

        var babies: [Baby] = []
        babies.append(contentsOf: (0..<boys).map { _ in Baby(sex: .male) })
        babies.append(contentsOf: (0..<girls).map { _ in Baby(sex: .female) })
        babies.append(contentsOf: (0..<losses).map { _ in Baby(sex: .loss) })

        let delivery = Delivery(
            date: Date(),
            babies: babies,
            babyCount: total,
            deliveryMethod: method,
            epiduralUsed: epiduralUsed,
            notes: "Added via Siri - may lack baby details."
        )
        for baby in babies { baby.delivery = delivery }

        deliveryManager.create(delivery: delivery)

        return .result(
            dialog: "Logged \(total) \(total == 1 ? "baby" : "babies"). Great work!"
        )
    }
}

extension LogDeliveryIntent {
    /// Donates an interaction mirroring a delivery the user logged through
    /// the app's UI, so Apple Intelligence / the new Siri can learn real
    /// usage patterns. Siri and Shortcuts executions are recorded by the
    /// system automatically — only call this from manual save paths, once
    /// per real save.
    @MainActor
    static func donate(reflecting delivery: Delivery) {
        let babies = delivery.babies ?? []

        let intent = LogDeliveryIntent()
        intent.boys = babies.count { $0.sex == .male }
        intent.girls = babies.count { $0.sex == .female }
        intent.losses = babies.count { $0.sex == .loss }
        intent.method = delivery.deliveryMethod
        intent.epiduralUsed = delivery.epiduralUsed

        Task {
            do {
                _ = try await IntentDonationManager.shared.donate(intent: intent)
            } catch {
                Log.app.error("Intent donation failed: \(error.localizedDescription)")
            }
        }
    }
}
