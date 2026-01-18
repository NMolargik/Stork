//
//  HomeView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import Foundation

private extension Int {
    /// Calculates this value as a percentage of a total
    func percentage(of total: Int) -> Double {
        total > 0 ? (Double(self) / Double(total)) * 100 : 0
    }
}

extension HomeView {
    @Observable
    class ViewModel {
        struct DeliveryMethodStats {
            let vaginalCount: Int
            let cSectionCount: Int
            let vBacCount: Int
            let total: Int
            var vaginalPercentage: Double { vaginalCount.percentage(of: total) }
            var cSectionPercentage: Double { cSectionCount.percentage(of: total) }
            var vBacPercentage: Double { vBacCount.percentage(of: total) }
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
            var malePercentage: Double { maleCount.percentage(of: total) }
            var femalePercentage: Double { femaleCount.percentage(of: total) }
            var lossPercentage: Double { lossCount.percentage(of: total) }
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

        // MARK: - Time of Day Analysis

        struct TimeOfDayStats {
            let hourCounts: [Int: Int] // hour (0-23) -> count
            let peakHour: Int?
            let peakCount: Int
            let total: Int

            var shiftBreakdown: (night: Int, morning: Int, afternoon: Int, evening: Int) {
                let night = (0..<6).reduce(0) { $0 + (hourCounts[$1] ?? 0) }      // 12am-6am
                let morning = (6..<12).reduce(0) { $0 + (hourCounts[$1] ?? 0) }   // 6am-12pm
                let afternoon = (12..<18).reduce(0) { $0 + (hourCounts[$1] ?? 0) } // 12pm-6pm
                let evening = (18..<24).reduce(0) { $0 + (hourCounts[$1] ?? 0) }  // 6pm-12am
                return (night, morning, afternoon, evening)
            }
        }

        func timeOfDayStats(deliveries: [Delivery]) -> TimeOfDayStats {
            var hourCounts: [Int: Int] = [:]
            for delivery in deliveries {
                let hour = Calendar.current.component(.hour, from: delivery.date)
                hourCounts[hour, default: 0] += 1
            }

            let peakEntry = hourCounts.max(by: { $0.value < $1.value })
            return TimeOfDayStats(
                hourCounts: hourCounts,
                peakHour: peakEntry?.key,
                peakCount: peakEntry?.value ?? 0,
                total: deliveries.count
            )
        }

        // MARK: - Day of Week Distribution

        struct DayOfWeekStats {
            let dayCounts: [Int: Int] // weekday (1=Sun, 7=Sat) -> count
            let busiestDay: Int?
            let busiestCount: Int
            let total: Int

            static let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            static let fullDayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        }

        func dayOfWeekStats(deliveries: [Delivery]) -> DayOfWeekStats {
            var dayCounts: [Int: Int] = [:]
            for delivery in deliveries {
                let weekday = Calendar.current.component(.weekday, from: delivery.date)
                dayCounts[weekday, default: 0] += 1
            }

            let busiestEntry = dayCounts.max(by: { $0.value < $1.value })
            return DayOfWeekStats(
                dayCounts: dayCounts,
                busiestDay: busiestEntry?.key,
                busiestCount: busiestEntry?.value ?? 0,
                total: deliveries.count
            )
        }

        // MARK: - Year over Year Comparison

        struct YearOverYearStats {
            let yearlyData: [(year: Int, deliveries: Int, babies: Int)]
            let currentYear: Int
            let currentYearDeliveries: Int
            let currentYearBabies: Int
            let previousYearDeliveries: Int
            let previousYearBabies: Int

            var deliveryGrowth: Double? {
                guard previousYearDeliveries > 0 else { return nil }
                return Double(currentYearDeliveries - previousYearDeliveries) / Double(previousYearDeliveries) * 100
            }

            var babyGrowth: Double? {
                guard previousYearBabies > 0 else { return nil }
                return Double(currentYearBabies - previousYearBabies) / Double(previousYearBabies) * 100
            }
        }

        func yearOverYearStats(deliveries: [Delivery]) -> YearOverYearStats {
            var yearlyDeliveries: [Int: Int] = [:]
            var yearlyBabies: [Int: Int] = [:]

            for delivery in deliveries {
                let year = Calendar.current.component(.year, from: delivery.date)
                yearlyDeliveries[year, default: 0] += 1
                yearlyBabies[year, default: 0] += delivery.babyCount
            }

            let currentYear = Calendar.current.component(.year, from: Date())
            let sortedYears = yearlyDeliveries.keys.sorted(by: >)
            let yearlyData = sortedYears.prefix(5).map { year in
                (year: year, deliveries: yearlyDeliveries[year] ?? 0, babies: yearlyBabies[year] ?? 0)
            }

            return YearOverYearStats(
                yearlyData: yearlyData,
                currentYear: currentYear,
                currentYearDeliveries: yearlyDeliveries[currentYear] ?? 0,
                currentYearBabies: yearlyBabies[currentYear] ?? 0,
                previousYearDeliveries: yearlyDeliveries[currentYear - 1] ?? 0,
                previousYearBabies: yearlyBabies[currentYear - 1] ?? 0
            )
        }

        // MARK: - Personal Bests

        struct PersonalBests {
            let mostDeliveriesInDay: (date: Date, count: Int)?
            let mostDeliveriesInWeek: (weekStart: Date, count: Int)?
            let mostDeliveriesInMonth: (monthStart: Date, count: Int)?
            let mostBabiesInDay: (date: Date, count: Int)?
            let longestStreak: Int // consecutive days with deliveries
        }

        func personalBests(deliveries: [Delivery]) -> PersonalBests {
            guard !deliveries.isEmpty else {
                return PersonalBests(
                    mostDeliveriesInDay: nil,
                    mostDeliveriesInWeek: nil,
                    mostDeliveriesInMonth: nil,
                    mostBabiesInDay: nil,
                    longestStreak: 0
                )
            }

            let cal = Calendar.current

            // Group by day
            var dailyDeliveries: [Date: Int] = [:]
            var dailyBabies: [Date: Int] = [:]
            for delivery in deliveries {
                let dayStart = cal.startOfDay(for: delivery.date)
                dailyDeliveries[dayStart, default: 0] += 1
                dailyBabies[dayStart, default: 0] += delivery.babyCount
            }

            // Group by week (Sunday start)
            var weeklyDeliveries: [Date: Int] = [:]
            for delivery in deliveries {
                var weekStart = cal.startOfDay(for: delivery.date)
                let weekday = cal.component(.weekday, from: weekStart)
                weekStart = cal.date(byAdding: .day, value: -(weekday - 1), to: weekStart) ?? weekStart
                weeklyDeliveries[weekStart, default: 0] += 1
            }

            // Group by month
            var monthlyDeliveries: [Date: Int] = [:]
            for delivery in deliveries {
                let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: delivery.date))!
                monthlyDeliveries[monthStart, default: 0] += 1
            }

            // Find bests
            let bestDay = dailyDeliveries.max(by: { $0.value < $1.value })
            let bestWeek = weeklyDeliveries.max(by: { $0.value < $1.value })
            let bestMonth = monthlyDeliveries.max(by: { $0.value < $1.value })
            let bestBabyDay = dailyBabies.max(by: { $0.value < $1.value })

            // Calculate longest streak
            let sortedDays = dailyDeliveries.keys.sorted()
            var longestStreak = 0
            var currentStreak = 0
            var previousDay: Date?

            for day in sortedDays {
                if let prev = previousDay {
                    let daysBetween = cal.dateComponents([.day], from: prev, to: day).day ?? 0
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else {
                        longestStreak = max(longestStreak, currentStreak)
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                previousDay = day
            }
            longestStreak = max(longestStreak, currentStreak)

            return PersonalBests(
                mostDeliveriesInDay: bestDay.map { ($0.key, $0.value) },
                mostDeliveriesInWeek: bestWeek.map { ($0.key, $0.value) },
                mostDeliveriesInMonth: bestMonth.map { ($0.key, $0.value) },
                mostBabiesInDay: bestBabyDay.map { ($0.key, $0.value) },
                longestStreak: longestStreak
            )
        }
    }
}
