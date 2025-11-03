//
//  HomeView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import Foundation

extension HomeView {
    @Observable
    class ViewModel {
        struct DeliveryMethodStats {
            let vaginalCount: Int
            let cSectionCount: Int
            let vBacCount: Int
            let total: Int
            var vaginalPercentage: Double { total > 0 ? (Double(vaginalCount) / Double(total)) * 100 : 0 }
            var cSectionPercentage: Double { total > 0 ? (Double(cSectionCount) / Double(total)) * 100 : 0 }
            var vBacPercentage: Double { total > 0 ? (Double(vBacCount) / Double(total)) * 100 : 0 }
        }

        struct MonthlyBabyCounts {
            let labels: [String]
            let counts: [Int]
        }

        struct BabyMeasurementStats {
            let averageWeight: Double
            let averageHeight: Double
            let count: Int
        }

        struct SexDistributionStats {
            let maleCount: Int
            let femaleCount: Int
            let lossCount: Int
            let total: Int
            var malePercentage: Double { total > 0 ? (Double(maleCount) / Double(total)) * 100 : 0 }
            var femalePercentage: Double { total > 0 ? (Double(femaleCount) / Double(total)) * 100 : 0 }
            var lossPercentage: Double { total > 0 ? (Double(lossCount) / Double(total)) * 100 : 0 }
        }

        // MARK: - Jar
        func monthlyJarCounts(deliveries: [Delivery]) -> (boy: Int, girl: Int, loss: Int) {
            let cal = Calendar.current
            let today = Date()
            let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
            let endExclusive = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? today

            let recentDeliveries = deliveries.filter { d in
                (d.date >= startOfMonth) && (d.date < endExclusive)
            }
            let babies = recentDeliveries.flatMap { $0.babies ?? [] }
            let boy  = babies.lazy.filter { $0.sex == .male }.count
            let girl = babies.lazy.filter { $0.sex == .female }.count
            let loss = babies.lazy.filter { $0.sex == .loss }.count
            return (boy, girl, loss)
        }

        // MARK: - Delivery Method
        func deliveryMethodStats(deliveries: [Delivery]) -> DeliveryMethodStats {
            let vaginalCount = deliveries.filter { $0.deliveryMethod == .vaginal }.count
            let cSectionCount = deliveries.filter { $0.deliveryMethod == .cSection }.count
            let vBacCount = deliveries.filter { $0.deliveryMethod == .vBac }.count
            let total = deliveries.count
            return DeliveryMethodStats(vaginalCount: vaginalCount, cSectionCount: cSectionCount, vBacCount: vBacCount, total: total)
        }

        // MARK: - Epidural
        func epiduralUsagePercentage(deliveries: [Delivery]) -> Double {
            guard !deliveries.isEmpty else { return 0 }
            let epiduralCount = deliveries.filter { $0.epiduralUsed }.count
            return (Double(epiduralCount) / Double(deliveries.count)) * 100
        }

        // MARK: - Babies per Delivery
        func averageBabyCount(deliveries: [Delivery]) -> Double {
            guard !deliveries.isEmpty else { return 0 }
            let totalBabies = deliveries.reduce(0) { $0 + ($1.babyCount) }
            return Double(totalBabies) / Double(deliveries.count)
        }

        func monthlyBabyCounts(deliveries: [Delivery]) -> MonthlyBabyCounts {
            guard !deliveries.isEmpty else { return MonthlyBabyCounts(labels: [], counts: []) }
            var monthlyCounts: [Date: Int] = [:]
            for delivery in deliveries {
                let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: delivery.date))!
                monthlyCounts[monthStart, default: 0] += delivery.babyCount
            }
            let sortedMonths = monthlyCounts.keys.sorted(by: >)
            let df = DateFormatter()
            df.locale = .current
            df.setLocalizedDateFormatFromTemplate("MMM yy")
            let labels = sortedMonths.map { df.string(from: $0).uppercased() }
            let counts = sortedMonths.map { monthlyCounts[$0] ?? 0 }
            return MonthlyBabyCounts(labels: labels, counts: counts)
        }

        func deliveryAndBabyTotals(deliveries: [Delivery]) -> (deliveries: Int, babies: Int) {
            (deliveries.count, deliveries.reduce(0) { $0 + ($1.babyCount) })
        }

        // MARK: - Measurements
        func babyMeasurementStats(deliveries: [Delivery]) -> BabyMeasurementStats {
            let allBabies = deliveries.flatMap { $0.babies ?? [] }
            guard !allBabies.isEmpty else { return BabyMeasurementStats(averageWeight: 0, averageHeight: 0, count: 0) }
            let totalWeight = allBabies.reduce(0.0) { $0 + $1.weight }
            let totalHeight = allBabies.reduce(0.0) { $0 + $1.height }
            let count = allBabies.count
            return BabyMeasurementStats(
                averageWeight: totalWeight / Double(count),
                averageHeight: totalHeight / Double(count),
                count: count
            )
        }

        // MARK: - NICU
        func nicuStayPercentage(deliveries: [Delivery]) -> Double {
            let allBabies = deliveries.flatMap { $0.babies ?? [] }
            guard !allBabies.isEmpty else { return 0 }
            let nicuCount = allBabies.filter { $0.nicuStay }.count
            return (Double(nicuCount) / Double(allBabies.count)) * 100
        }

        // MARK: - Sex Distribution
        func sexDistribution(deliveries: [Delivery]) -> SexDistributionStats {
            let allBabies = deliveries.flatMap { $0.babies ?? [] }
            let maleCount = allBabies.filter { $0.sex == .male }.count
            let femaleCount = allBabies.filter { $0.sex == .female }.count
            let lossCount = allBabies.filter { $0.sex == .loss }.count
            let total = allBabies.count
            return SexDistributionStats(maleCount: maleCount, femaleCount: femaleCount, lossCount: lossCount, total: total)
        }
    }
}
