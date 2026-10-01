//
//  DeliveryStatistics.swift
//  StorkCore
//
//  Every dashboard statistic, as pure deterministic functions over a set of deliveries
//  with an injectable `Calendar`/`Date`. No persistence, no UI. Touches the `@Model`
//  types so it runs on the MainActor like the rest of the SwiftData surface.
//

import Foundation

private extension Int {
    /// This value as a percentage of `total`, or 0 when `total` is 0.
    func percentage(of total: Int) -> Double {
        total > 0 ? (Double(self) / Double(total)) * 100 : 0
    }
}

public enum DeliveryStatistics {

    // MARK: - Result types

    public struct DeliveryMethodStats {
        public let vaginalCount: Int
        public let cSectionCount: Int
        public let vBacCount: Int
        public let total: Int
        public var vaginalPercentage: Double { vaginalCount.percentage(of: total) }
        public var cSectionPercentage: Double { cSectionCount.percentage(of: total) }
        public var vBacPercentage: Double { vBacCount.percentage(of: total) }
    }

    public struct MonthlyBabyCounts {
        public let labels: [String]
        public let counts: [Int]
    }

    public struct BabyMeasurementStats {
        public let averageWeight: Double
        public let averageHeight: Double
        public let count: Int
    }

    public struct SexDistributionStats {
        public let maleCount: Int
        public let femaleCount: Int
        public let lossCount: Int
        public let total: Int
        public var malePercentage: Double { maleCount.percentage(of: total) }
        public var femalePercentage: Double { femaleCount.percentage(of: total) }
        public var lossPercentage: Double { lossCount.percentage(of: total) }
    }

    public struct TimeOfDayStats {
        public let hourCounts: [Int: Int] // hour (0-23) -> count
        public let peakHour: Int?
        public let peakCount: Int
        public let total: Int

        public var shiftBreakdown: (night: Int, morning: Int, afternoon: Int, evening: Int) {
            let night = (0..<6).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
            let morning = (6..<12).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
            let afternoon = (12..<18).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
            let evening = (18..<24).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
            return (night, morning, afternoon, evening)
        }
    }

    public struct DayOfWeekStats {
        public let dayCounts: [Int: Int] // weekday (1=Sun, 7=Sat) -> count
        public let busiestDay: Int?
        public let busiestCount: Int
        public let total: Int

        public static let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        public static let fullDayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    }

    public struct YearOverYearStats {
        public let yearlyData: [(year: Int, deliveries: Int, babies: Int)]
        public let currentYear: Int
        public let currentYearDeliveries: Int
        public let currentYearBabies: Int
        public let previousYearDeliveries: Int
        public let previousYearBabies: Int

        public var deliveryGrowth: Double? {
            guard previousYearDeliveries > 0 else { return nil }
            return Double(currentYearDeliveries - previousYearDeliveries) / Double(previousYearDeliveries) * 100
        }

        public var babyGrowth: Double? {
            guard previousYearBabies > 0 else { return nil }
            return Double(currentYearBabies - previousYearBabies) / Double(previousYearBabies) * 100
        }
    }

    public struct PersonalBests {
        public let mostDeliveriesInDay: (date: Date, count: Int)?
        public let mostDeliveriesInWeek: (weekStart: Date, count: Int)?
        public let mostDeliveriesInMonth: (monthStart: Date, count: Int)?
        public let mostBabiesInDay: (date: Date, count: Int)?
        public let longestStreak: Int // consecutive days with deliveries
    }

    // MARK: - Totals

    public static func totals(deliveries: [Delivery]) -> (deliveries: Int, babies: Int) {
        (deliveries.count, deliveries.reduce(0) { $0 + $1.babyCount })
    }

    public static func averageBabyCount(deliveries: [Delivery]) -> Double {
        guard !deliveries.isEmpty else { return 0 }
        let totalBabies = deliveries.reduce(0) { $0 + $1.babyCount }
        return Double(totalBabies) / Double(deliveries.count)
    }

    // MARK: - Current month (jar)

    public static func monthlyJarCounts(
        deliveries: [Delivery],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> (boy: Int, girl: Int, loss: Int) {
        let startOfMonth = WeekMath.startOfMonth(for: date, calendar: calendar)
        let endExclusive = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? date

        let babies = deliveries
            .filter { $0.date >= startOfMonth && $0.date < endExclusive }
            .flatMap { $0.babies ?? [] }
        let boy = babies.count { $0.sex == .male }
        let girl = babies.count { $0.sex == .female }
        let loss = babies.count { $0.sex == .loss }
        return (boy, girl, loss)
    }

    // MARK: - Method / epidural / NICU

    public static func deliveryMethodStats(deliveries: [Delivery]) -> DeliveryMethodStats {
        DeliveryMethodStats(
            vaginalCount: deliveries.count { $0.deliveryMethod == .vaginal },
            cSectionCount: deliveries.count { $0.deliveryMethod == .cSection },
            vBacCount: deliveries.count { $0.deliveryMethod == .vBac },
            total: deliveries.count
        )
    }

    public static func epiduralUsagePercentage(deliveries: [Delivery]) -> Double {
        guard !deliveries.isEmpty else { return 0 }
        let epiduralCount = deliveries.count { $0.epiduralUsed }
        return (Double(epiduralCount) / Double(deliveries.count)) * 100
    }

    public static func nicuStayPercentage(deliveries: [Delivery]) -> Double {
        let allBabies = deliveries.flatMap { $0.babies ?? [] }
        guard !allBabies.isEmpty else { return 0 }
        let nicuCount = allBabies.count { $0.nicuStay }
        return (Double(nicuCount) / Double(allBabies.count)) * 100
    }

    // MARK: - Babies

    public static func babyMeasurementStats(deliveries: [Delivery]) -> BabyMeasurementStats {
        let allBabies = deliveries.flatMap { $0.babies ?? [] }
        guard !allBabies.isEmpty else {
            return BabyMeasurementStats(averageWeight: 0, averageHeight: 0, count: 0)
        }
        let totalWeight = allBabies.reduce(0.0) { $0 + $1.weight }
        let totalHeight = allBabies.reduce(0.0) { $0 + $1.height }
        let count = allBabies.count
        return BabyMeasurementStats(
            averageWeight: totalWeight / Double(count),
            averageHeight: totalHeight / Double(count),
            count: count
        )
    }

    public static func sexDistribution(deliveries: [Delivery]) -> SexDistributionStats {
        let allBabies = deliveries.flatMap { $0.babies ?? [] }
        return SexDistributionStats(
            maleCount: allBabies.count { $0.sex == .male },
            femaleCount: allBabies.count { $0.sex == .female },
            lossCount: allBabies.count { $0.sex == .loss },
            total: allBabies.count
        )
    }

    public static func monthlyBabyCounts(deliveries: [Delivery], calendar: Calendar = .current) -> MonthlyBabyCounts {
        guard !deliveries.isEmpty else { return MonthlyBabyCounts(labels: [], counts: []) }
        var monthlyCounts: [Date: Int] = [:]
        for delivery in deliveries {
            let monthStart = WeekMath.startOfMonth(for: delivery.date, calendar: calendar)
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

    // MARK: - Timing patterns

    public static func timeOfDayStats(deliveries: [Delivery], calendar: Calendar = .current) -> TimeOfDayStats {
        var hourCounts: [Int: Int] = [:]
        for delivery in deliveries {
            let hour = calendar.component(.hour, from: delivery.date)
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

    public static func dayOfWeekStats(deliveries: [Delivery], calendar: Calendar = .current) -> DayOfWeekStats {
        var dayCounts: [Int: Int] = [:]
        for delivery in deliveries {
            let weekday = calendar.component(.weekday, from: delivery.date)
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

    public static func yearOverYearStats(
        deliveries: [Delivery],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> YearOverYearStats {
        var yearlyDeliveries: [Int: Int] = [:]
        var yearlyBabies: [Int: Int] = [:]

        for delivery in deliveries {
            let year = calendar.component(.year, from: delivery.date)
            yearlyDeliveries[year, default: 0] += 1
            yearlyBabies[year, default: 0] += delivery.babyCount
        }

        let currentYear = calendar.component(.year, from: date)
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

    public static func personalBests(deliveries: [Delivery], calendar: Calendar = .current) -> PersonalBests {
        guard !deliveries.isEmpty else {
            return PersonalBests(
                mostDeliveriesInDay: nil,
                mostDeliveriesInWeek: nil,
                mostDeliveriesInMonth: nil,
                mostBabiesInDay: nil,
                longestStreak: 0
            )
        }

        var dailyDeliveries: [Date: Int] = [:]
        var dailyBabies: [Date: Int] = [:]
        var weeklyDeliveries: [Date: Int] = [:]
        var monthlyDeliveries: [Date: Int] = [:]

        for delivery in deliveries {
            let dayStart = calendar.startOfDay(for: delivery.date)
            dailyDeliveries[dayStart, default: 0] += 1
            dailyBabies[dayStart, default: 0] += delivery.babyCount

            let weekday = calendar.component(.weekday, from: dayStart)
            let weekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: dayStart) ?? dayStart
            weeklyDeliveries[weekStart, default: 0] += 1

            let monthStart = WeekMath.startOfMonth(for: delivery.date, calendar: calendar)
            monthlyDeliveries[monthStart, default: 0] += 1
        }

        let bestDay = dailyDeliveries.max(by: { $0.value < $1.value })
        let bestWeek = weeklyDeliveries.max(by: { $0.value < $1.value })
        let bestMonth = monthlyDeliveries.max(by: { $0.value < $1.value })
        let bestBabyDay = dailyBabies.max(by: { $0.value < $1.value })

        // Longest run of consecutive days that each had at least one delivery.
        let sortedDays = dailyDeliveries.keys.sorted()
        var longestStreak = 0
        var currentStreak = 0
        var previousDay: Date?

        for day in sortedDays {
            if let prev = previousDay,
               calendar.dateComponents([.day], from: prev, to: day).day == 1 {
                currentStreak += 1
            } else {
                longestStreak = max(longestStreak, currentStreak)
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
