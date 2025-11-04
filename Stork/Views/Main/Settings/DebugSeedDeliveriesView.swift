//
//  DebugSeedDeliveriesView.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData

struct DebugSeedDeliveriesView: View {
    let hospitalId: String

    @Environment(\.modelContext) private var modelContext
    @State private var isWorking = false
    @State private var lastSummary: String?

    var body: some View {
        VStack(spacing: 16) {
            Button {
                Task { await seedSixMonths() }
            } label: {
                HStack {
                    if isWorking { ProgressView() }
                    Text(isWorking ? "Seeding…" : "Insert 8 Months of Sample Data")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isWorking)

            Button(role: .destructive) {
                Task { await wipeAll() }
            } label: {
                Text("Delete All Deliveries")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let lastSummary {
                Text(lastSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("Seed Deliveries (Debug)")
    }

    // MARK: - Seeding

    @MainActor
    private func seedSixMonths() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let cal = Calendar.current
        let now = Date()
        let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now

        // Distributions (see notes above)
        let pCSection = 0.323
        let pVBAC = 0.02                   // overall slice so VBACs appear
        let pMale = 0.511
        let pLoss = 0.0055                 // stillbirth proxy at >=20w
        let pPreterm = 0.1041
        let pNICUBase = 0.098
        let pTwins = 0.0307
        let pTripPlus = 0.000738
        let pNurseCatch = 0.10
        let pEpiduralVag = 0.70

        // We’ll model what a single nurse logs each month: ~15 ± 3
        func monthlyDeliveryTarget() -> Int {
            max(6, Int(round(normal(mean: 15.0, sd: 3.0))))
        }

        var inserted = 0
        var insertedBabies = 0

        for monthBack in (0..<8).reversed() {
            let monthStart = cal.date(byAdding: .month, value: -monthBack, to: startOfThisMonth) ?? startOfThisMonth
            let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
            let days = cal.dateComponents([.day], from: monthStart, to: min(nextMonth, now)).day ?? 28

            let deliveriesThisMonth = monthlyDeliveryTarget()
            for _ in 0..<deliveriesThisMonth {
                // Pick a random timestamp within the month (avoid future dates if current month)
                let randomDay = Int.random(in: 0..<max(days,1))
                let dayDate = cal.date(byAdding: .day, value: randomDay, to: monthStart) ?? monthStart
                let hour = Int.random(in: 0..<24)
                let minute = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55].randomElement() ?? 0
                var when = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayDate) ?? dayDate
                if when > now { when = now.addingTimeInterval(-60) } // clamp to now

                // Delivery method
                let methodPick = Double.random(in: 0...1)
                let method: DeliveryMethod = {
                    if methodPick < pCSection { return .cSection }
                    else if methodPick < (pCSection + pVBAC) { return .vBac }
                    else { return .vaginal }
                }()

                // Epidural / neuraxial use
                let epiduralUsed: Bool = {
                    switch method {
                    case .cSection, .vBac: return true
                    case .vaginal: return Bool.random(probability: pEpiduralVag)
                    }
                }()

                // Single vs multiples
                let multPick = Double.random(in: 0...1)
                let babyCount: Int = {
                    if multPick < pTripPlus { return 3 }
                    else if multPick < (pTripPlus + pTwins) { return 2 }
                    else { return 1 }
                }()

                // Create the babies with realistic variation
                var babies: [Baby] = []
                for _ in 0..<babyCount {
                    // Sex / loss
                    let r = Double.random(in: 0...1)
                    let sex: Sex = (r < pLoss) ? .loss : (r < pLoss + pMale ? .male : .female)

                    // Preterm flag (for NICU + size bias)
                    let isPreterm = Bool.random(probability: pPreterm)

                    // NICU bias: higher if preterm, lower if term
                    let nicuProb = min(0.85, isPreterm ? (pNICUBase + 0.40) : (pNICUBase * 0.85))
                    let nicuStay = Bool.random(probability: nicuProb)

                    // Nurse catch: rare but possible
                    let nurseCatch = Bool.random(probability: pNurseCatch)

                    // Weight (ounces) and length (inches) ~rough normal; lighter if preterm
                    let weightOz: Double
                    let lengthIn: Double
                    if isPreterm {
                        weightOz = clamp(normal(mean: 88, sd: 18), min: 40, max: 130) // ~5.5 lb avg
                        lengthIn = clamp(normal(mean: 18.0, sd: 1.0), min: 14.0, max: 20.5)
                    } else {
                        weightOz = clamp(normal(mean: 120, sd: 16), min: 70, max: 160) // ~7.5 lb avg
                        lengthIn = clamp(normal(mean: 20.0, sd: 0.9), min: 18.0, max: 22.5)
                    }

                    let baby = Baby(
                        nurseCatch: nurseCatch,
                        nicuStay: nicuStay,
                        sex: sex,
                        weight: weightOz,
                        height: lengthIn,
                        birthday: when,
                        delivery: nil
                    )
                    babies.append(baby)
                }

                let delivery = Delivery(
                    date: when,
                    hospitalId: hospitalId,
                    babies: babies,
                    babyCount: babies.count,
                    deliveryMethod: method,
                    epiduralUsed: epiduralUsed
                )

                // Maintain inverse relationship for SwiftData
                for b in babies { b.delivery = delivery }

                modelContext.insert(delivery)
                inserted += 1
                insertedBabies += babies.count
            }
        }

        do {
            try modelContext.save()
        } catch {
            lastSummary = "Save failed: \(error.localizedDescription)"
            return
        }

        // If your app lives on DeliveryManager.shared, refresh it.
        await MainActor.run {
            if let manager = DeliveryManager.shared {
                Task { await manager.refresh() }
            }
        }

        lastSummary = "Inserted \(inserted) deliveries and \(insertedBabies) babies across the last 8 months."
    }

    // MARK: - Wipe

    @MainActor
    private func wipeAll() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            // Delete all Delivery models; Baby cascades per deleteRule: .cascade
            let all = try modelContext.fetch(FetchDescriptor<Delivery>())
            all.forEach { modelContext.delete($0) }
            try modelContext.save()
            // Keep DeliveryManager in sync if present
            await DeliveryManager.shared?.refresh()
            lastSummary = "Deleted all deliveries (and babies via cascade)."
        } catch {
            lastSummary = "Delete failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Small helpers

fileprivate func clamp(_ x: Double, min lo: Double, max hi: Double) -> Double {
    Swift.max(lo, Swift.min(hi, x))
}

/// Box–Muller normal sampler
fileprivate func normal(mean: Double, sd: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(max(u1, 1e-12))) * cos(2.0 * .pi * u2)
    return mean + sd * z0
}

fileprivate extension Bool {
    static func random(probability p: Double) -> Bool {
        guard p > 0 else { return false }
        if p >= 1 { return true }
        return Double.random(in: 0...1) < p
    }
}
