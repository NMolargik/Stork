//
//  DeliveryStatistics.swift
//  Stork
//

import Foundation

private extension Int {
    /// This value as a percentage of `total`, or 0 when `total` is 0.
    func percentage(of total: Int) -> Double {
        total > 0 ? (Double(self) / Double(total)) * 100 : 0
    }
}

/// Pure statistics over a set of deliveries. Every function is deterministic
/// given its inputs — no persistence, no UI, fully unit-testable.
enum DeliveryStatistics {

    // MARK: - Result types

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

    struct TimeOfDayStats {
        let hourCounts: [Int: Int] // hour (0-23) -> count
        let peakHour: Int?
        let peakCount: Int
        let total: Int

        var shiftBreakdown: (night: Int, morning: Int, afternoon: Int, evening: Int) {
            let night = (0..<6).reduce(0) { $0 + (hourCounts[$1] ?? 0) }       // 12am-6am
            let morning = (6..<12).reduce(0) { $0 + (hourCounts[$1] ?? 0) }    // 6am-12pm
            let afternoon = (12..<18).reduce(0) { $0 + (hourCounts[$1] ?? 0) } // 12pm-6pm
            let evening = (18..<24).reduce(0) { $0 + (hourCounts[$1] ?? 0) }   // 6pm-12am
            return (night, morning, afternoon, evening)
        }
    }

    struct DayOfWeekStats {
        let dayCounts: [Int: Int] // weekday (1=Sun, 7=Sat) -> count
        let busiestDay: Int?
        let busiestCount: Int
        let total: Int

        static let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        static let fullDayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    }

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

    struct PersonalBests {
        let mostDeliveriesInDay: (date: Date, count: Int)?
        let mostDeliveriesInWeek: (weekStart: Date, count: Int)?
        let mostDeliveriesInMonth: (monthStart: Date, count: Int)?
        let mostBabiesInDay: (date: Date, count: Int)?
        let longestStreak: Int // consecutive days with deliveries
    }

    // MARK: - Totals

    static func totals(deliveries: [Delivery]) -> (deliveries: Int, babies: Int) {
        (deliveries.count, deliveries.reduce(0) { $0 + $1.babyCount })
    }

    static func averageBabyCount(deliveries: [Delivery]) -> Double {
        guard !deliveries.isEmpty else { return 0 }
        let totalBabies = deliveries.reduce(0) { $0 + $1.babyCount }
        return Double(totalBabies) / Double(deliveries.count)
    }

    // MARK: - Current month (jar)

    static func monthlyJarCounts(
        deliveries: [Delivery],
        asOf date: Date = Date(),
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

    static func deliveryMethodStats(deliveries: [Delivery]) -> DeliveryMethodStats {
        DeliveryMethodStats(
            vaginalCount: deliveries.count { $0.deliveryMethod == .vaginal },
            cSectionCount: deliveries.count { $0.deliveryMethod == .cSection },
            vBacCount: deliveries.count { $0.deliveryMethod == .vBac },
            total: deliveries.count
        )
    }

    static func epiduralUsagePercentage(deliveries: [Delivery]) -> Double {
        guard !deliveries.isEmpty else { return 0 }
        let epiduralCount = deliveries.count { $0.epiduralUsed }
        return (Double(epiduralCount) / Double(deliveries.count)) * 100
    }

    static func nicuStayPercentage(deliveries: [Delivery]) -> Double {
        let allBabies = deliveries.flatMap { $0.babies ?? [] }
        guard !allBabies.isEmpty else { return 0 }
        let nicuCount = allBabies.count { $0.nicuStay }
        return (Double(nicuCount) / Double(allBabies.count)) * 100
    }

    // MARK: - Babies

    static func babyMeasurementStats(deliveries: [Delivery]) -> BabyMeasurementStats {
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

    static func sexDistribution(deliveries: [Delivery]) -> SexDistributionStats {
        let allBabies = deliveries.flatMap { $0.babies ?? [] }
        return SexDistributionStats(
            maleCount: allBabies.count { $0.sex == .male },
            femaleCount: allBabies.count { $0.sex == .female },
            lossCount: allBabies.count { $0.sex == .loss },
            total: allBabies.count
        )
    }

    static func monthlyBabyCounts(deliveries: [Delivery], calendar: Calendar = .current) -> MonthlyBabyCounts {
        guard !deliveries.isEmpty else { return MonthlyBabyCounts(labels: [], counts: []) }
        var monthlyCounts: [Date: Int] = [:]
        for delivery in deliveries {
            let monthStart = WeekMath.startOfMonth(for: delivery.date, calendar: calendar)
            monthlyCounts[monthStart, default: 0] += delivery.babyCount
        }
        let sortedMonths = monthlyCounts.keys.sorted(by: >)
        let labels = sortedMonths.map { monthLabelFormatter.string(from: $0).uppercased() }
        let counts = sortedMonths.map { monthlyCounts[$0] ?? 0 }
        return MonthlyBabyCounts(labels: labels, counts: counts)
    }

    // MARK: - Timing patterns

    static func timeOfDayStats(deliveries: [Delivery], calendar: Calendar = .current) -> TimeOfDayStats {
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

    static func dayOfWeekStats(deliveries: [Delivery], calendar: Calendar = .current) -> DayOfWeekStats {
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

    static func yearOverYearStats(
        deliveries: [Delivery],
        asOf date: Date = Date(),
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

    static func personalBests(deliveries: [Delivery], calendar: Calendar = .current) -> PersonalBests {
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

    // MARK: - Formatting

    private static let monthLabelFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM yy")
        return df
    }()
}
