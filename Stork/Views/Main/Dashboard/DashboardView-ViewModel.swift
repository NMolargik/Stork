//
//  DashboardView-ViewModel.swift
//  Stork
//

import Foundation

extension DashboardView {
    /// Thin presentation adapter. All statistics math lives in
    /// `DeliveryStatistics`, which is pure and unit-tested directly.
    @Observable
    class ViewModel {
        typealias DeliveryMethodStats = DeliveryStatistics.DeliveryMethodStats
        typealias MonthlyBabyCounts = DeliveryStatistics.MonthlyBabyCounts
        typealias BabyMeasurementStats = DeliveryStatistics.BabyMeasurementStats
        typealias SexDistributionStats = DeliveryStatistics.SexDistributionStats
        typealias TimeOfDayStats = DeliveryStatistics.TimeOfDayStats
        typealias DayOfWeekStats = DeliveryStatistics.DayOfWeekStats
        typealias YearOverYearStats = DeliveryStatistics.YearOverYearStats
        typealias PersonalBests = DeliveryStatistics.PersonalBests

        func monthlyJarCounts(deliveries: [Delivery]) -> (boy: Int, girl: Int, loss: Int) {
            DeliveryStatistics.monthlyJarCounts(deliveries: deliveries)
        }

        func deliveryMethodStats(deliveries: [Delivery]) -> DeliveryMethodStats {
            DeliveryStatistics.deliveryMethodStats(deliveries: deliveries)
        }

        func epiduralUsagePercentage(deliveries: [Delivery]) -> Double {
            DeliveryStatistics.epiduralUsagePercentage(deliveries: deliveries)
        }

        func averageBabyCount(deliveries: [Delivery]) -> Double {
            DeliveryStatistics.averageBabyCount(deliveries: deliveries)
        }

        func monthlyBabyCounts(deliveries: [Delivery]) -> MonthlyBabyCounts {
            DeliveryStatistics.monthlyBabyCounts(deliveries: deliveries)
        }

        func deliveryAndBabyTotals(deliveries: [Delivery]) -> (deliveries: Int, babies: Int) {
            DeliveryStatistics.totals(deliveries: deliveries)
        }

        func babyMeasurementStats(deliveries: [Delivery]) -> BabyMeasurementStats {
            DeliveryStatistics.babyMeasurementStats(deliveries: deliveries)
        }

        func nicuStayPercentage(deliveries: [Delivery]) -> Double {
            DeliveryStatistics.nicuStayPercentage(deliveries: deliveries)
        }

        func sexDistribution(deliveries: [Delivery]) -> SexDistributionStats {
            DeliveryStatistics.sexDistribution(deliveries: deliveries)
        }

        func timeOfDayStats(deliveries: [Delivery]) -> TimeOfDayStats {
            DeliveryStatistics.timeOfDayStats(deliveries: deliveries)
        }

        func dayOfWeekStats(deliveries: [Delivery]) -> DayOfWeekStats {
            DeliveryStatistics.dayOfWeekStats(deliveries: deliveries)
        }

        func yearOverYearStats(deliveries: [Delivery]) -> YearOverYearStats {
            DeliveryStatistics.yearOverYearStats(deliveries: deliveries)
        }

        func personalBests(deliveries: [Delivery]) -> PersonalBests {
            DeliveryStatistics.personalBests(deliveries: deliveries)
        }
    }
}
