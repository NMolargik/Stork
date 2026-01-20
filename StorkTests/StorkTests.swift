//
//  StorkTests.swift
//  StorkTests
//
//  Created by Nick Molargik on 1/17/26.
//

import Testing
import Foundation
@testable import Stork

// MARK: - Delivery Model Tests

@Suite("Delivery Model Tests")
struct DeliveryModelTests {

    @Test("Delivery initializes with correct values")
    func deliveryInitialization() {
        let date = Date()
        let delivery = Delivery(
            date: date,
            babyCount: 2,
            deliveryMethod: .vaginal,
            epiduralUsed: true
        )

        #expect(delivery.date == date)
        #expect(delivery.babyCount == 2)
        #expect(delivery.deliveryMethod == .vaginal)
        #expect(delivery.epiduralUsed == true)
        #expect(delivery.babies?.isEmpty ?? true)
    }

    @Test("Delivery sample creates valid instance")
    func deliverySample() {
        let sample = Delivery.sample()

        #expect(sample.babyCount == 3)
        #expect(sample.deliveryMethod == .vaginal)
        #expect(sample.epiduralUsed == true)
        #expect(sample.babies?.count == 3)
    }

    @Test("Delivery has unique UUID")
    func deliveryUniqueId() {
        let delivery1 = Delivery(date: Date(), babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
        let delivery2 = Delivery(date: Date(), babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)

        #expect(delivery1.id != delivery2.id)
    }
}

// MARK: - Baby Model Tests

@Suite("Baby Model Tests")
struct BabyModelTests {

    @Test("Baby initializes with correct values")
    func babyInitialization() {
        let birthday = Date()
        let baby = Baby(
            birthday: birthday,
            height: 20.0,
            weight: 128.0,
            nurseCatch: true,
            nicuStay: false,
            sex: .male
        )

        #expect(baby.birthday == birthday)
        #expect(baby.height == 20.0)
        #expect(baby.weight == 128.0)
        #expect(baby.nurseCatch == true)
        #expect(baby.nicuStay == false)
        #expect(baby.sex == .male)
    }

    @Test("Baby convenience initializer works correctly")
    func babyConvenienceInit() {
        let baby = Baby(nurseCatch: true, nicuStay: true, sex: .female)

        #expect(baby.nurseCatch == true)
        #expect(baby.nicuStay == true)
        #expect(baby.sex == .female)
        #expect(baby.weight == 121.6) // default
        #expect(baby.height == 19.0) // default
    }

    @Test("Baby sample creates valid instance")
    func babySample() {
        let sample = Baby.sample

        #expect(sample.sex == .male)
        #expect(sample.nurseCatch == true)
        #expect(sample.nicuStay == false)
        #expect(sample.height == 19.5)
        #expect(sample.weight == 122.0)
    }

    @Test("Baby sample function with parameters")
    func babySampleWithParams() {
        let baby = Baby.sample(nicuStay: true, sex: .loss)

        #expect(baby.sex == Sex.loss)
        #expect(baby.nicuStay == true)
    }
}

// MARK: - Sex Enumeration Tests

@Suite("Sex Enumeration Tests")
struct SexEnumerationTests {

    @Test("Sex has correct descriptions")
    func sexDescriptions() {
        #expect(Sex.male.description == "Male")
        #expect(Sex.female.description == "Female")
        #expect(Sex.loss.description == "Loss")
    }

    @Test("Sex has correct display names")
    func sexDisplayNames() {
        #expect(Sex.male.displayName == "Boy")
        #expect(Sex.female.displayName == "Girl")
        #expect(Sex.loss.displayName == "Loss")
    }

    @Test("Sex has correct short display")
    func sexDisplayShort() {
        #expect(Sex.male.displayShort == "M")
        #expect(Sex.female.displayShort == "F")
        #expect(Sex.loss.displayShort == "Loss")
    }

    @Test("Sex raw values are correct")
    func sexRawValues() {
        #expect(Sex.male.rawValue == "male")
        #expect(Sex.female.rawValue == "female")
        #expect(Sex.loss.rawValue == "loss")
    }

    @Test("Sex has all cases")
    func sexAllCases() {
        #expect(Sex.allCases.count == 3)
        #expect(Sex.allCases.contains(.male))
        #expect(Sex.allCases.contains(.female))
        #expect(Sex.allCases.contains(.loss))
    }
}

// MARK: - DeliveryMethod Enumeration Tests

@Suite("DeliveryMethod Enumeration Tests")
struct DeliveryMethodEnumerationTests {

    @Test("DeliveryMethod has correct descriptions")
    func deliveryMethodDescriptions() {
        #expect(DeliveryMethod.vaginal.description == "Vaginal")
        #expect(DeliveryMethod.cSection.description == "C-Section")
        #expect(DeliveryMethod.vBac.description == "VBAC")
    }

    @Test("DeliveryMethod has correct display names")
    func deliveryMethodDisplayNames() {
        #expect(DeliveryMethod.vaginal.displayName == "Vaginal")
        #expect(DeliveryMethod.cSection.displayName == "Cesarean")
        #expect(DeliveryMethod.vBac.displayName == "VBAC")
    }

    @Test("DeliveryMethod raw values are correct")
    func deliveryMethodRawValues() {
        #expect(DeliveryMethod.vaginal.rawValue == "vaginal")
        #expect(DeliveryMethod.cSection.rawValue == "cSection")
        #expect(DeliveryMethod.vBac.rawValue == "vBac")
    }

    @Test("DeliveryMethod has all cases")
    func deliveryMethodAllCases() {
        #expect(DeliveryMethod.allCases.count == 3)
    }
}

// MARK: - Unit Conversion Tests

@Suite("Unit Conversion Tests")
struct UnitConversionTests {

    @Test("Weight display in imperial")
    func weightDisplayImperial() {
        let result = UnitConversion.weightDisplay(120.0, useMetric: false)
        #expect(result == "120.0 oz")
    }

    @Test("Weight display in metric")
    func weightDisplayMetric() {
        let result = UnitConversion.weightDisplay(120.0, useMetric: true)
        // 120 oz * 28.349523125 = 3401.94 g, rounded to 3402
        #expect(result == "3402 g")
    }

    @Test("Height display in imperial")
    func heightDisplayImperial() {
        let result = UnitConversion.heightDisplay(19.5, useMetric: false)
        #expect(result == "19.5 in")
    }

    @Test("Height display in metric")
    func heightDisplayMetric() {
        let result = UnitConversion.heightDisplay(19.5, useMetric: true)
        // 19.5 * 2.54 = 49.53
        #expect(result == "49.5 cm")
    }

    @Test("Ounces to display weight conversion - imperial")
    func ouncesToDisplayWeightImperial() {
        let result = UnitConversion.ouncesToDisplayWeight(100.0, useMetric: false)
        #expect(result == 100.0)
    }

    @Test("Ounces to display weight conversion - metric")
    func ouncesToDisplayWeightMetric() {
        let result = UnitConversion.ouncesToDisplayWeight(100.0, useMetric: true)
        let expected = 100.0 * UnitConversion.ouncesToGrams
        #expect(result == expected)
    }

    @Test("Display weight to ounces conversion - imperial")
    func displayWeightToOuncesImperial() {
        let result = UnitConversion.displayWeightToOunces(100.0, useMetric: false)
        #expect(result == 100.0)
    }

    @Test("Display weight to ounces conversion - metric")
    func displayWeightToOuncesMetric() {
        let grams = 2834.95 // approximately 100 oz
        let result = UnitConversion.displayWeightToOunces(grams, useMetric: true)
        #expect(abs(result - 100.0) < 0.1)
    }

    @Test("Inches to display height conversion")
    func inchesToDisplayHeight() {
        let resultImperial = UnitConversion.inchesToDisplayHeight(20.0, useMetric: false)
        let resultMetric = UnitConversion.inchesToDisplayHeight(20.0, useMetric: true)

        #expect(resultImperial == 20.0)
        #expect(resultMetric == 20.0 * UnitConversion.inchesToCentimeters)
    }

    @Test("Display height to inches conversion")
    func displayHeightToInches() {
        let resultImperial = UnitConversion.displayHeightToInches(20.0, useMetric: false)
        let cm = 50.8 // 20 inches
        let resultMetric = UnitConversion.displayHeightToInches(cm, useMetric: true)

        #expect(resultImperial == 20.0)
        #expect(abs(resultMetric - 20.0) < 0.01)
    }

    @Test("Weight height summary - imperial")
    func weightHeightSummaryImperial() {
        // 128 oz = 8 lb 0 oz, 20 inches = 1 ft 8 in
        let result = UnitConversion.weightHeightSummary(weightOunces: 128.0, heightInches: 20.0, useMetric: false)
        #expect(result == "8 lb 0 oz, 1 ft 8 in")
    }

    @Test("Conversion factors are correct")
    func conversionFactors() {
        #expect(UnitConversion.ouncesToGrams == 28.349523125)
        #expect(UnitConversion.inchesToCentimeters == 2.54)
        #expect(UnitConversion.centimetersToInches == 0.393701)
    }
}

// MARK: - Date Formatting Tests

@Suite("Date Formatting Tests")
struct DateFormattingTests {

    @Test("formattedMediumDateTime produces non-empty string")
    func formattedMediumDateTime() {
        let date = Date()
        let result = date.formattedMediumDateTime()

        #expect(!result.isEmpty)
    }

    @Test("formattedForDelivery with day-month-year format")
    func formattedForDeliveryDayMonthYear() {
        let components = DateComponents(year: 2026, month: 1, day: 15, hour: 14, minute: 30)
        let date = Calendar.current.date(from: components)!

        let result = date.formattedForDelivery(useDayMonthYear: true)

        #expect(result.contains("15/01/2026"))
    }

    @Test("formattedForDelivery with long date style")
    func formattedForDeliveryLongStyle() {
        let components = DateComponents(year: 2026, month: 1, day: 15, hour: 14, minute: 30)
        let date = Calendar.current.date(from: components)!

        let result = date.formattedForDelivery(useDayMonthYear: false)

        // Long date style includes month name
        #expect(result.contains("January") || result.contains("15"))
    }
}

// MARK: - AppTab Tests

@Suite("AppTab Tests")
struct AppTabTests {

    @Test("AppTab has correct raw values")
    func appTabRawValues() {
        #expect(AppTab.home.rawValue == "Dashboard")
        #expect(AppTab.list.rawValue == "Deliveries")
        #expect(AppTab.calendar.rawValue == "Calendar")
        #expect(AppTab.settings.rawValue == "Settings")
    }

    @Test("AppTab has all cases")
    func appTabAllCases() {
        #expect(AppTab.allCases.count == 4)
    }

    @Test("AppTab icons are not nil")
    func appTabIcons() {
        for tab in AppTab.allCases {
            // Just verify icon() doesn't crash
            _ = tab.icon()
        }
    }

    @Test("AppTab colors are defined")
    func appTabColors() {
        for tab in AppTab.allCases {
            // Just verify color() doesn't crash
            _ = tab.color()
        }
    }
}

// MARK: - Export Date Range Tests

@Suite("ExportDateRange Tests")
struct ExportDateRangeTests {

    @Test("ExportDateRange has all expected cases")
    func exportDateRangeAllCases() {
        #expect(ExportDateRange.allCases.count == 6)
        #expect(ExportDateRange.allCases.contains(.thisMonth))
        #expect(ExportDateRange.allCases.contains(.lastMonth))
        #expect(ExportDateRange.allCases.contains(.thisYear))
        #expect(ExportDateRange.allCases.contains(.lastYear))
        #expect(ExportDateRange.allCases.contains(.allTime))
        #expect(ExportDateRange.allCases.contains(.custom))
    }

    @Test("ExportDateRange has correct display names")
    func exportDateRangeDisplayNames() {
        #expect(ExportDateRange.thisMonth.displayName == "This Month")
        #expect(ExportDateRange.lastMonth.displayName == "Last Month")
        #expect(ExportDateRange.thisYear.displayName == "This Year")
        #expect(ExportDateRange.lastYear.displayName == "Last Year")
        #expect(ExportDateRange.allTime.displayName == "All Time")
        #expect(ExportDateRange.custom.displayName == "Custom Range")
    }

    @Test("ExportDateRange thisMonth returns valid interval")
    func exportDateRangeThisMonth() {
        let now = Date()
        let interval = ExportDateRange.thisMonth.dateInterval()

        #expect(interval != nil)
        #expect(interval!.start <= now)
        // End should be at or near now (within a second)
        #expect(interval!.end.timeIntervalSince(now) >= -1)
    }

    @Test("ExportDateRange lastMonth returns interval in the past")
    func exportDateRangeLastMonth() {
        let interval = ExportDateRange.lastMonth.dateInterval()

        #expect(interval != nil)
        #expect(interval!.end <= Date())
    }

    @Test("ExportDateRange thisYear includes today")
    func exportDateRangeThisYear() {
        let now = Date()
        let interval = ExportDateRange.thisYear.dateInterval()

        #expect(interval != nil)
        // Start of year should be before now, end should be at or near now
        #expect(interval!.start <= now)
        #expect(interval!.end.timeIntervalSince(now) >= -1)
    }

    @Test("ExportDateRange allTime returns nil (no filtering)")
    func exportDateRangeAllTime() {
        let interval = ExportDateRange.allTime.dateInterval()

        #expect(interval == nil)
    }

    @Test("ExportDateRange custom returns nil (requires manual dates)")
    func exportDateRangeCustom() {
        let interval = ExportDateRange.custom.dateInterval()

        #expect(interval == nil)
    }
}

// MARK: - CSVRowFormat Tests

@Suite("CSVRowFormat Tests")
struct CSVRowFormatTests {

    @Test("CSVRowFormat has all expected cases")
    func csvRowFormatAllCases() {
        #expect(CSVRowFormat.allCases.count == 2)
        #expect(CSVRowFormat.allCases.contains(.perDelivery))
        #expect(CSVRowFormat.allCases.contains(.perBaby))
    }

    @Test("CSVRowFormat has correct display names")
    func csvRowFormatDisplayNames() {
        #expect(CSVRowFormat.perDelivery.displayName == "One Row per Delivery")
        #expect(CSVRowFormat.perBaby.displayName == "One Row per Baby")
    }

    @Test("CSVRowFormat has descriptions")
    func csvRowFormatDescriptions() {
        #expect(!CSVRowFormat.perDelivery.description.isEmpty)
        #expect(!CSVRowFormat.perBaby.description.isEmpty)
    }
}

// MARK: - ExportError Tests

@Suite("ExportError Tests")
struct ExportErrorTests {

    @Test("ExportError has localized descriptions")
    func exportErrorDescriptions() {
        let pdfError = ExportError.pdfGenerationFailed("test")
        let csvError = ExportError.csvExportFailed("test")
        let imageError = ExportError.imageRenderingFailed("test")
        let fileError = ExportError.fileCreationFailed("test")
        let noDataError = ExportError.noDataToExport
        let dateRangeError = ExportError.invalidDateRange

        #expect(pdfError.errorDescription != nil)
        #expect(csvError.errorDescription != nil)
        #expect(imageError.errorDescription != nil)
        #expect(fileError.errorDescription != nil)
        #expect(noDataError.errorDescription != nil)
        #expect(dateRangeError.errorDescription != nil)
    }

    @Test("ExportError message property works")
    func exportErrorMessages() {
        let error = ExportError.pdfGenerationFailed("custom message")
        #expect(error.message.contains("custom message"))

        let noDataError = ExportError.noDataToExport
        #expect(noDataError.message.contains("deliveries"))
    }
}

// MARK: - CardImageRenderer CardType Tests

@Suite("CardImageRenderer.CardType Tests")
struct CardTypeTests {

    @Test("CardType has all expected cases")
    func cardTypeAllCases() {
        #expect(CardImageRenderer.CardType.allCases.count == 6)
    }

    @Test("CardType has display names")
    func cardTypeDisplayNames() {
        #expect(CardImageRenderer.CardType.deliveryMethod.displayName == "Delivery Method")
        #expect(CardImageRenderer.CardType.sexDistribution.displayName == "Sex Distribution")
        #expect(CardImageRenderer.CardType.babyCount.displayName == "Baby Count")
        #expect(CardImageRenderer.CardType.epiduralUsage.displayName == "Epidural Usage")
        #expect(CardImageRenderer.CardType.nicuStay.displayName == "NICU Stays")
        #expect(CardImageRenderer.CardType.babyMeasurements.displayName == "Baby Measurements")
    }

    @Test("CardType has icon names")
    func cardTypeIconNames() {
        for cardType in CardImageRenderer.CardType.allCases {
            #expect(!cardType.iconName.isEmpty)
        }
    }
}

// MARK: - CardImageRenderer MilestoneType Tests

@Suite("CardImageRenderer.MilestoneType Tests")
struct MilestoneTypeTests {

    @Test("MilestoneType has all expected cases")
    func milestoneTypeAllCases() {
        #expect(CardImageRenderer.MilestoneType.allCases.count == 2)
        #expect(CardImageRenderer.MilestoneType.allCases.contains(.babies))
        #expect(CardImageRenderer.MilestoneType.allCases.contains(.deliveries))
    }

    @Test("MilestoneType has display names")
    func milestoneTypeDisplayNames() {
        #expect(CardImageRenderer.MilestoneType.babies.displayName == "Babies")
        #expect(CardImageRenderer.MilestoneType.deliveries.displayName == "Deliveries")
    }

    @Test("MilestoneType display templates are correct")
    func milestoneTypeDisplayTemplates() {
        let babiesTemplate = CardImageRenderer.MilestoneType.babies.displayTemplate(count: 500)
        let deliveriesTemplate = CardImageRenderer.MilestoneType.deliveries.displayTemplate(count: 100)

        #expect(babiesTemplate.contains("500"))
        #expect(babiesTemplate.contains("babies"))
        #expect(deliveriesTemplate.contains("100"))
        #expect(deliveriesTemplate.contains("deliveries"))
    }

    @Test("MilestoneType handles singular correctly")
    func milestoneTypeSingular() {
        let babySingular = CardImageRenderer.MilestoneType.babies.displayTemplate(count: 1)
        let deliverySingular = CardImageRenderer.MilestoneType.deliveries.displayTemplate(count: 1)

        #expect(babySingular.contains("baby"))
        #expect(!babySingular.contains("babies"))
        #expect(deliverySingular.contains("delivery"))
        #expect(!deliverySingular.contains("deliveries"))
    }
}

// MARK: - DeliveryManager Milestone Tests

@Suite("DeliveryManager Milestone Tests")
struct DeliveryManagerMilestoneTests {

    @Test("DeliveryManager has baby milestone thresholds")
    func deliveryManagerBabyMilestones() {
        let milestones = DeliveryManager.babyMilestones

        #expect(milestones.contains(100))
        #expect(milestones.contains(250))
        #expect(milestones.contains(500))
        #expect(milestones.contains(1000))
    }

    @Test("DeliveryManager has delivery milestone thresholds")
    func deliveryManagerDeliveryMilestones() {
        let milestones = DeliveryManager.deliveryMilestones

        #expect(milestones.contains(50))
        #expect(milestones.contains(100))
        #expect(milestones.contains(250))
        #expect(milestones.contains(500))
        #expect(milestones.contains(1000))
    }

    @Test("MilestoneCelebration type equality works")
    func milestoneCelebrationEquality() {
        let milestone1 = DeliveryManager.MilestoneCelebration(count: 100, type: .babies)
        let milestone2 = DeliveryManager.MilestoneCelebration(count: 100, type: .babies)
        let milestone3 = DeliveryManager.MilestoneCelebration(count: 100, type: .deliveries)
        let milestone4 = DeliveryManager.MilestoneCelebration(count: 500, type: .babies)

        #expect(milestone1 == milestone2)
        #expect(milestone1 != milestone3)
        #expect(milestone1 != milestone4)
    }
}

// MARK: - HomeView.ViewModel Analytics Tests

@Suite("HomeView.ViewModel Analytics Tests")
struct HomeViewModelAnalyticsTests {

    @Test("TimeOfDayStats calculates shift breakdown correctly")
    func timeOfDayShiftBreakdown() {
        let viewModel = HomeView.ViewModel()

        // Create deliveries at different times
        var deliveries: [Delivery] = []

        // Night shift (12am-6am) - 2 deliveries
        let nightDate1 = makeDate(hour: 2)
        let nightDate2 = makeDate(hour: 4)
        deliveries.append(Delivery(date: nightDate1, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        deliveries.append(Delivery(date: nightDate2, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        // Morning shift (6am-12pm) - 3 deliveries
        let morningDate1 = makeDate(hour: 8)
        let morningDate2 = makeDate(hour: 10)
        let morningDate3 = makeDate(hour: 11)
        deliveries.append(Delivery(date: morningDate1, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        deliveries.append(Delivery(date: morningDate2, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        deliveries.append(Delivery(date: morningDate3, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        // Afternoon shift (12pm-6pm) - 1 delivery
        let afternoonDate = makeDate(hour: 14)
        deliveries.append(Delivery(date: afternoonDate, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        // Evening shift (6pm-12am) - 2 deliveries
        let eveningDate1 = makeDate(hour: 20)
        let eveningDate2 = makeDate(hour: 22)
        deliveries.append(Delivery(date: eveningDate1, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        deliveries.append(Delivery(date: eveningDate2, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        let stats = viewModel.timeOfDayStats(deliveries: deliveries)

        #expect(stats.total == 8)
        let shifts = stats.shiftBreakdown
        #expect(shifts.night == 2)
        #expect(shifts.morning == 3)
        #expect(shifts.afternoon == 1)
        #expect(shifts.evening == 2)
    }

    @Test("TimeOfDayStats finds peak hour")
    func timeOfDayPeakHour() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        // 3 deliveries at 10am
        for _ in 0..<3 {
            deliveries.append(Delivery(date: makeDate(hour: 10), babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }
        // 1 delivery at 2pm
        deliveries.append(Delivery(date: makeDate(hour: 14), babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        let stats = viewModel.timeOfDayStats(deliveries: deliveries)

        #expect(stats.peakHour == 10)
        #expect(stats.peakCount == 3)
    }

    @Test("TimeOfDayStats handles empty deliveries")
    func timeOfDayEmptyDeliveries() {
        let viewModel = HomeView.ViewModel()
        let stats = viewModel.timeOfDayStats(deliveries: [])

        #expect(stats.total == 0)
        #expect(stats.peakHour == nil)
        #expect(stats.peakCount == 0)
    }

    @Test("DayOfWeekStats calculates day counts correctly")
    func dayOfWeekCounts() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        // Create deliveries on different days
        let cal = Calendar.current

        // Find a known Sunday
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 4 // January 4, 2026 is a Sunday
        let sunday = cal.date(from: components)!

        // Add 3 deliveries on Sunday
        for _ in 0..<3 {
            deliveries.append(Delivery(date: sunday, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        // Add 1 delivery on Monday
        let monday = cal.date(byAdding: .day, value: 1, to: sunday)!
        deliveries.append(Delivery(date: monday, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        let stats = viewModel.dayOfWeekStats(deliveries: deliveries)

        #expect(stats.total == 4)
        #expect(stats.busiestDay == 1) // Sunday = 1
        #expect(stats.busiestCount == 3)
    }

    @Test("DayOfWeekStats has correct day names")
    func dayOfWeekDayNames() {
        #expect(HomeView.ViewModel.DayOfWeekStats.dayNames.count == 8) // includes empty string at index 0
        #expect(HomeView.ViewModel.DayOfWeekStats.dayNames[1] == "Sun")
        #expect(HomeView.ViewModel.DayOfWeekStats.dayNames[7] == "Sat")
        #expect(HomeView.ViewModel.DayOfWeekStats.fullDayNames[1] == "Sunday")
        #expect(HomeView.ViewModel.DayOfWeekStats.fullDayNames[7] == "Saturday")
    }

    @Test("YearOverYearStats calculates yearly totals")
    func yearOverYearTotals() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let cal = Calendar.current

        // Current year deliveries
        let currentYear = cal.component(.year, from: Date())
        var components = DateComponents()
        components.year = currentYear
        components.month = 1
        components.day = 15
        let currentYearDate = cal.date(from: components)!

        for _ in 0..<5 {
            deliveries.append(Delivery(date: currentYearDate, babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        // Previous year deliveries
        components.year = currentYear - 1
        let previousYearDate = cal.date(from: components)!

        for _ in 0..<3 {
            deliveries.append(Delivery(date: previousYearDate, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        let stats = viewModel.yearOverYearStats(deliveries: deliveries)

        #expect(stats.currentYear == currentYear)
        #expect(stats.currentYearDeliveries == 5)
        #expect(stats.currentYearBabies == 10) // 5 deliveries * 2 babies
        #expect(stats.previousYearDeliveries == 3)
        #expect(stats.previousYearBabies == 3) // 3 deliveries * 1 baby
    }

    @Test("YearOverYearStats calculates growth percentages")
    func yearOverYearGrowth() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let cal = Calendar.current

        let currentYear = cal.component(.year, from: Date())
        var components = DateComponents()

        // Current year: 10 deliveries
        components.year = currentYear
        components.month = 1
        components.day = 15
        let currentYearDate = cal.date(from: components)!
        for _ in 0..<10 {
            deliveries.append(Delivery(date: currentYearDate, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        // Previous year: 5 deliveries (100% growth)
        components.year = currentYear - 1
        let previousYearDate = cal.date(from: components)!
        for _ in 0..<5 {
            deliveries.append(Delivery(date: previousYearDate, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        let stats = viewModel.yearOverYearStats(deliveries: deliveries)

        #expect(stats.deliveryGrowth == 100.0) // (10-5)/5 * 100 = 100%
        #expect(stats.babyGrowth == 100.0)
    }

    @Test("YearOverYearStats handles no previous year data")
    func yearOverYearNoPreviousYear() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let currentYearDate = Date()
        deliveries.append(Delivery(date: currentYearDate, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))

        let stats = viewModel.yearOverYearStats(deliveries: deliveries)

        #expect(stats.deliveryGrowth == nil)
        #expect(stats.babyGrowth == nil)
    }

    @Test("PersonalBests finds most deliveries in a day")
    func personalBestsMostInDay() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let today = Date()
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        // 5 deliveries today
        for _ in 0..<5 {
            deliveries.append(Delivery(date: today, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        // 2 deliveries yesterday
        for _ in 0..<2 {
            deliveries.append(Delivery(date: yesterday, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        let stats = viewModel.personalBests(deliveries: deliveries)

        #expect(stats.mostDeliveriesInDay?.count == 5)
    }

    @Test("PersonalBests finds most babies in a day")
    func personalBestsMostBabiesInDay() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let today = Date()
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        // 2 deliveries today with 3 babies each = 6 babies
        deliveries.append(Delivery(date: today, babyCount: 3, deliveryMethod: .vaginal, epiduralUsed: false))
        deliveries.append(Delivery(date: today, babyCount: 3, deliveryMethod: .vaginal, epiduralUsed: false))

        // 3 deliveries yesterday with 1 baby each = 3 babies
        for _ in 0..<3 {
            deliveries.append(Delivery(date: yesterday, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        let stats = viewModel.personalBests(deliveries: deliveries)

        #expect(stats.mostBabiesInDay?.count == 6)
    }

    @Test("PersonalBests calculates longest streak")
    func personalBestsLongestStreak() {
        let viewModel = HomeView.ViewModel()

        var deliveries: [Delivery] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Create 5 consecutive days of deliveries
        for dayOffset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -dayOffset, to: today)!
            deliveries.append(Delivery(date: date, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false))
        }

        let stats = viewModel.personalBests(deliveries: deliveries)

        #expect(stats.longestStreak == 5)
    }

    @Test("PersonalBests handles empty deliveries")
    func personalBestsEmptyDeliveries() {
        let viewModel = HomeView.ViewModel()
        let stats = viewModel.personalBests(deliveries: [])

        #expect(stats.mostDeliveriesInDay == nil)
        #expect(stats.mostDeliveriesInWeek == nil)
        #expect(stats.mostDeliveriesInMonth == nil)
        #expect(stats.mostBabiesInDay == nil)
        #expect(stats.longestStreak == 0)
    }

    // Helper function to create a date with a specific hour
    private func makeDate(hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = hour
        return Calendar.current.date(from: components)!
    }
}
