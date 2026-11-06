//
//  ProTests.swift
//  StorkCoreTests
//
//  Stork Pro domain rules: the grandfather decision for pre-3.0 buyers, the feature
//  catalog, the back-dating rule, the milestone-share review prompt, and the weather value.
//

import Testing
import Foundation
@testable import StorkCore

// MARK: - Grandfathering

@Suite("GrandfatherPolicy Tests")
struct GrandfatherPolicyTests {

    @Test("Paid-era production builds below 300 are grandfathered", arguments: ["1", "33", "41", "53", "120", "299"])
    func paidBuildsQualify(build: String) {
        #expect(GrandfatherPolicy.qualifies(originalAppVersion: build, isProduction: true))
    }

    @Test("The first free build and everything after it are not", arguments: ["300", "301", "350", "1000"])
    func freeBuildsDoNot(build: String) {
        #expect(!GrandfatherPolicy.qualifies(originalAppVersion: build, isProduction: true))
    }

    @Test("Non-production receipts never grandfather, whatever version they report", arguments: ["1", "1.0", "53", "299", "2.4"])
    func sandboxNeverQualifies(version: String) {
        #expect(!GrandfatherPolicy.qualifies(originalAppVersion: version, isProduction: false))
    }

    @Test("Dotted versions compare numerically against 3.0", arguments: [
        ("2.4", true), ("2.4.1", true), ("2.10", true), ("1.0", true), ("3.0", false), ("3.0.0", false), ("3.0.1", false), ("10.0", false)
    ])
    func dottedVersions(version: String, expected: Bool) {
        #expect(GrandfatherPolicy.qualifies(originalAppVersion: version, isProduction: true) == expected)
    }

    @Test("Garbage input is rejected rather than crashing", arguments: ["", "abc", "-5", "3.x", " 53 "])
    func garbage(version: String) {
        let expected = version.trimmingCharacters(in: .whitespaces) == "53"
        #expect(GrandfatherPolicy.qualifies(originalAppVersion: version, isProduction: true) == expected)
    }

    @Test("VersionNumber orders numerically and treats trailing zeros as insignificant")
    func versionNumber() throws {
        #expect(try #require(VersionNumber("53")) < #require(VersionNumber("300")))
        #expect(try #require(VersionNumber("2.10")) > #require(VersionNumber("2.4")))
        #expect(try #require(VersionNumber("3.0")) == #require(VersionNumber("3.0.0")))
        #expect(VersionNumber("") == nil)
        #expect(VersionNumber("1..2") == nil)
    }

    @Test("Constants match the shipped build and App Store Connect product")
    func constants() {
        #expect(GrandfatherPolicy.firstFreeBuild == "300")
        #expect(GrandfatherPolicy.firstFreeMarketingVersion == "3.0")
        #expect(StorkProProduct.id == "com.nickmolargik.stork.pro.lifetime")
    }
}

// MARK: - Feature catalog

@Suite("ProFeature Catalog Tests")
struct ProFeatureTests {

    @Test("Exactly the insight cards require Pro; basic count cards are free")
    func dashboardCardGating() {
        let pro = Set(DashboardCard.allCases.filter(\.requiresPro))
        #expect(pro == [.babyMeasurements, .timeOfDay, .dayOfWeek, .yearOverYear, .personalBests])
        #expect(!DashboardCard.deliveryMethod.requiresPro)
        #expect(!DashboardCard.epiduralNicu.requiresPro)
        #expect(!DashboardCard.babyCount.requiresPro)
        #expect(!DashboardCard.sexDistribution.requiresPro)
    }

    @Test("Every Pro feature has a name and a symbol")
    func featureMetadata() {
        for feature in ProFeature.allCases {
            #expect(!feature.displayName.isEmpty)
            #expect(!feature.systemImage.isEmpty)
        }
        #expect(ProFeature.allCases.count == 9)
    }

    @Test("stork://pro deep-links to the paywall on the Settings tab")
    func proDeepLink() {
        let link = DeepLink(url: URL(string: "stork://pro")!)
        #expect(link == .pro)
        #expect(link?.destinationTab == .settings)
    }
}

// MARK: - Back-dating

@Suite("DeliveryDateRule Tests")
struct DeliveryDateRuleTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Any past date is allowed, including years ago", arguments: [60.0, 86_400.0, 400 * 86_400.0, 20 * 365 * 86_400.0])
    func pastDatesAllowed(secondsAgo: Double) {
        let date = now.addingTimeInterval(-secondsAgo)
        #expect(DeliveryDateRule.isAllowed(date, now: now))
        #expect(DeliveryDateRule.clamped(date, now: now) == date)
    }

    @Test("Now is allowed; the future is not and clamps back to now")
    func futureRejected() {
        #expect(DeliveryDateRule.isAllowed(now, now: now))
        let future = now.addingTimeInterval(1)
        #expect(!DeliveryDateRule.isAllowed(future, now: now))
        #expect(DeliveryDateRule.clamped(future, now: now) == now)
    }

    @Test("Weather snapshots are offered only inside the 24-hour window")
    func weatherWindow() {
        #expect(DeliveryDateRule.allowsWeatherSnapshot(now, now: now))
        #expect(DeliveryDateRule.allowsWeatherSnapshot(now.addingTimeInterval(-23 * 3600), now: now))
        #expect(!DeliveryDateRule.allowsWeatherSnapshot(now.addingTimeInterval(-25 * 3600), now: now))
        #expect(!DeliveryDateRule.allowsWeatherSnapshot(now.addingTimeInterval(60), now: now))
    }
}

// MARK: - Review prompt after first milestone share

@Suite("MilestoneShareReviewPolicy Tests")
@MainActor
struct MilestoneShareReviewPolicyTests {

    @Test("Prompts exactly once across repeated shares")
    func promptsOnce() {
        let storage = FakeKeyValueStore()
        let requester = FakeReviewRequester()
        let policy = MilestoneShareReviewPolicy(storage: storage, requester: requester)

        policy.milestoneCardShared()
        policy.milestoneCardShared()
        policy.milestoneCardShared()

        #expect(requester.requestCount == 1)
        #expect(storage.bool(forKey: MilestoneShareReviewPolicy.defaultStorageKey))
    }

    @Test("The prompt flag persists across relaunch through storage")
    func persistsAcrossRelaunch() {
        let storage = FakeKeyValueStore()
        MilestoneShareReviewPolicy(storage: storage, requester: FakeReviewRequester()).milestoneCardShared()

        let requester = FakeReviewRequester()
        MilestoneShareReviewPolicy(storage: storage, requester: requester).milestoneCardShared()

        #expect(requester.requestCount == 0)
    }

    @Test("No requester (watch) means no prompt and no flag")
    func noRequester() {
        let storage = FakeKeyValueStore()
        MilestoneShareReviewPolicy(storage: storage, requester: nil).milestoneCardShared()
        #expect(!storage.bool(forKey: MilestoneShareReviewPolicy.defaultStorageKey))
    }
}

// MARK: - Weather value

@Suite("DeliveryWeather Tests")
@MainActor
struct DeliveryWeatherTests {

    @Test("Round-trips through the flat Delivery columns")
    func roundTrip() {
        let delivery = Delivery(date: .now, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
        #expect(delivery.weather == nil)

        let snapshot = DeliveryWeather(temperatureCelsius: -3.5, conditionName: "snow", symbolName: "cloud.snow.fill")
        delivery.weather = snapshot
        #expect(delivery.weather == snapshot)
        #expect(delivery.weatherConditionName == "snow")

        delivery.weather = nil
        #expect(delivery.weatherTemperatureCelsius == nil)
        #expect(delivery.weatherSymbolName == nil)
    }

    @Test("Temperature formats in the chosen unit as whole degrees")
    func temperatureFormatting() {
        let weather = DeliveryWeather(temperatureCelsius: 22.2, conditionName: "clear", symbolName: "sun.max.fill")
        #expect(weather.temperatureString(useMetric: true).contains("22"))
        #expect(weather.temperatureString(useMetric: false).contains("72"))
    }

    @Test("Condition names read as words")
    func conditionDisplay() {
        #expect(DeliveryWeather(temperatureCelsius: 0, conditionName: "partlyCloudy", symbolName: "").conditionDisplayName == "Partly Cloudy")
        #expect(DeliveryWeather(temperatureCelsius: 0, conditionName: "rain", symbolName: "").conditionDisplayName == "Rain")
    }
}
