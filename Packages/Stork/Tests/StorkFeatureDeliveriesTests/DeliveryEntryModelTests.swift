//
//  DeliveryEntryModelTests.swift
//  StorkFeatureDeliveriesTests
//
//  Behavior tests for the entry form's view model: validation, baby/tag editing,
//  save routing (log vs update), milestone passthrough, and error propagation.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureDeliveries

@Suite("DeliveryEntryModel Tests")
@MainActor
struct DeliveryEntryModelTests {

    // MARK: - Defaults & validation

    @Test("A new entry defaults to vaginal + epidural with no babies")
    func newEntryDefaults() {
        let model = Make.entryModel(data: FakeDeliveryData())

        #expect(!model.isEditing)
        #expect(model.deliveryMethod == .vaginal)
        #expect(model.epiduralUsed)
        #expect(model.babies.isEmpty)
        #expect(!model.canFinish)   // at least one baby required
    }

    @Test("Editing prefills every field from the existing delivery")
    func editPrefills() {
        let existing = Make.delivery(babyCount: 2, method: .cSection, notes: "note")
        let model = Make.entryModel(data: FakeDeliveryData(), existing: existing)

        #expect(model.isEditing)
        #expect(model.deliveryMethod == .cSection)
        #expect(model.babies.count == 2)
        #expect(model.notes == "note")
        #expect(model.canFinish)
    }

    // MARK: - Back-dating (any past date, never the future)

    @Test("A new delivery can be back-dated to any past date", arguments: [
        1.0, 4.0, 30.0, 400.0, 3650.0   // days ago
    ])
    func backDatingAnyPastDate(daysAgo: Double) throws {
        let opened = Date(timeIntervalSince1970: 1_800_000_000)
        let data = FakeDeliveryData()
        let model = Make.entryModel(data: data, now: opened)
        model.upsert(Baby(sex: .female))
        model.date = opened.addingTimeInterval(-daysAgo * 24 * 3600)

        model.clampDate()   // must not move a past date

        #expect(model.date == opened.addingTimeInterval(-daysAgo * 24 * 3600))
        #expect(model.canFinish)
        try model.save()
        #expect(data.loggedDeliveries.first?.date == model.date)
    }

    @Test("A future date is invalid until clamped back to the moment the form opened")
    func futureDateClampsToNow() {
        let opened = Date(timeIntervalSince1970: 1_800_000_000)
        let model = Make.entryModel(data: FakeDeliveryData(), now: opened)
        model.upsert(Baby(sex: .male))
        model.date = opened.addingTimeInterval(3600)

        #expect(!model.canFinish)
        model.clampDate()
        #expect(model.date == opened)
        #expect(model.canFinish)
    }

    @Test("The upper bound is fixed when the form opens so validation can't drift")
    func upperBoundIsFixedAtOpen() {
        let opened = Date(timeIntervalSince1970: 1_800_000_000)
        let model = Make.entryModel(data: FakeDeliveryData(), now: opened)
        #expect(model.dateUpperBound == opened)
        #expect(model.date == opened)   // a fresh form always validates
    }

    @Test("An old delivery being edited stays valid and clampDate is a no-op")
    func editingKeepsOriginalDate() {
        let old = Make.delivery(date: Date(timeIntervalSinceNow: -90 * 24 * 3600))
        let model = Make.entryModel(data: FakeDeliveryData(), existing: old)
        #expect(model.canFinish)
        model.clampDate()
        #expect(model.date == old.date)
    }

    // MARK: - Role

    @Test("Role defaults to not recorded, saves on new deliveries, and prefills + updates on edit")
    func roleSavesAndEdits() throws {
        let data = FakeDeliveryData()
        let model = Make.entryModel(data: data)
        #expect(model.role == nil)
        model.upsert(Baby(sex: .female))
        model.role = .transitionNurse
        try model.save()
        #expect(data.loggedDeliveries.first?.role == .transitionNurse)

        let existing = Make.delivery()
        existing.role = .preceptor
        let edit = Make.entryModel(data: data, existing: existing)
        #expect(edit.role == .preceptor)
        edit.role = nil
        try edit.save()
        #expect(existing.role == nil)
    }

    // MARK: - Weather snapshot gating (Stork Pro)

    @Test("Without a weather source the form never offers a snapshot")
    func noWeatherSourceHidesWeather() {
        let model = Make.entryModel(data: FakeDeliveryData(), entitlement: FakeEntitlement(unlocked: true))
        #expect(!model.supportsWeather)
        #expect(!model.canCaptureWeather)
    }

    @Test("Free users see the weather row but cannot capture")
    func freeUserCannotCaptureWeather() async {
        let weather = FakeWeatherCapture()
        let model = Make.entryModel(data: FakeDeliveryData(), entitlement: FakeEntitlement(), weather: weather)
        #expect(model.supportsWeather)
        #expect(!model.isProUnlocked)
        #expect(!model.canCaptureWeather)

        await model.captureWeather()

        #expect(weather.captureCount == 0)   // location is never requested for a locked feature
        #expect(model.weather == nil)
    }

    @Test("Pro users capture a snapshot that is saved with the delivery")
    func proUserCapturesAndSavesWeather() async throws {
        let data = FakeDeliveryData()
        let weather = FakeWeatherCapture()
        let model = Make.entryModel(data: data, entitlement: FakeEntitlement(unlocked: true), weather: weather)
        model.upsert(Baby(sex: .female))
        #expect(model.canCaptureWeather)

        await model.captureWeather()
        #expect(weather.captureCount == 1)
        #expect(model.weather == weather.snapshot)

        try model.save()
        #expect(data.loggedDeliveries.first?.weather == weather.snapshot)
        #expect(data.loggedDeliveries.first?.weatherTemperatureCelsius == 21)
    }

    @Test("Unlocking Pro mid-form enables capture without rebuilding the model")
    func entitlementIsReadLive() {
        let entitlement = FakeEntitlement()
        let model = Make.entryModel(data: FakeDeliveryData(), entitlement: entitlement, weather: FakeWeatherCapture())
        #expect(!model.canCaptureWeather)
        entitlement.isProUnlocked = true
        #expect(model.canCaptureWeather)
    }

    @Test("Back-dated deliveries older than 24 hours can't take a live snapshot")
    func oldDeliveryCannotCaptureWeather() {
        let opened = Date(timeIntervalSince1970: 1_800_000_000)
        let model = Make.entryModel(data: FakeDeliveryData(), entitlement: FakeEntitlement(unlocked: true), weather: FakeWeatherCapture(), now: opened)
        model.date = opened.addingTimeInterval(-2 * 24 * 3600)
        #expect(!model.isDateRecentEnoughForWeather)
        #expect(!model.canCaptureWeather)

        model.date = opened.addingTimeInterval(-6 * 3600)
        #expect(model.canCaptureWeather)
    }

    @Test("Weather capture failures surface as a message and leave no snapshot")
    func weatherFailureSurfaces() async {
        let weather = FakeWeatherCapture()
        weather.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "no fix"])
        let model = Make.entryModel(data: FakeDeliveryData(), entitlement: FakeEntitlement(unlocked: true), weather: weather)

        await model.captureWeather()

        #expect(model.weather == nil)
        #expect(model.weatherErrorMessage == "no fix")
        model.removeWeather()
        #expect(model.weatherErrorMessage == nil)
    }

    // MARK: - Babies

    @Test("upsert appends a new baby and replaces an edited one by id")
    func upsertBaby() {
        let model = Make.entryModel(data: FakeDeliveryData())
        let baby = Baby(sex: .male)
        model.upsert(baby)
        #expect(model.babies.count == 1)

        let edited = Baby(id: baby.id, sex: .female)
        model.upsert(edited)
        #expect(model.babies.count == 1)
        #expect(model.babies.first?.sex == .female)

        model.removeBaby(id: baby.id)
        #expect(model.babies.isEmpty)
    }

    // MARK: - Tags

    @Test("createAndSelectTag saves a new tag through the use-case exactly once")
    func createTag() {
        let data = FakeDeliveryData()
        let model = Make.entryModel(data: data)
        model.loadTags()

        model.createAndSelectTag(name: "Night Shift", colorHex: "5856D6")

        #expect(data.savedTags.count == 1)
        #expect(model.selectedTags.map(\.name) == ["Night Shift"])
    }

    @Test("createAndSelectTag reuses an existing tag case-insensitively")
    func createTagDedupes() {
        let data = FakeDeliveryData()
        let existing = DeliveryTag(name: "Night Shift")
        data.tags = [existing]
        let model = Make.entryModel(data: data)
        model.loadTags()

        model.createAndSelectTag(name: "night shift", colorHex: "FF0000")

        #expect(data.savedTags.isEmpty)                       // nothing new persisted
        #expect(model.selectedTags.map(\.id) == [existing.id]) // existing tag selected
    }

    // MARK: - Save routing

    @Test("Saving a new entry routes to LogDelivery and returns the milestone")
    func saveNewLogsAndReturnsMilestone() throws {
        let data = FakeDeliveryData()
        data.milestoneToReturn = MilestoneCelebration(count: 50, type: .deliveries)
        let model = Make.entryModel(data: data)
        model.upsert(Baby(sex: .male))
        model.notes = ""

        let milestone = try model.save()

        #expect(data.loggedDeliveries.count == 1)
        #expect(data.updatedDeliveries.isEmpty)
        #expect(milestone == MilestoneCelebration(count: 50, type: .deliveries))
        #expect(data.loggedDeliveries.first?.notes == nil)   // empty notes stored as nil
        #expect(data.loggedDeliveries.first?.babyCount == 1)
    }

    @Test("Saving an edit mutates the existing delivery and routes to UpdateDelivery")
    func saveEditUpdates() throws {
        let existing = Make.delivery(babyCount: 1, method: .vaginal)
        let data = FakeDeliveryData()
        let model = Make.entryModel(data: data, existing: existing)
        model.deliveryMethod = .vBac
        model.upsert(Baby(sex: .male))

        let milestone = try model.save()

        #expect(milestone == nil)                            // edits never celebrate
        #expect(data.updatedDeliveries.map(\.id) == [existing.id])
        #expect(data.loggedDeliveries.isEmpty)
        #expect(existing.deliveryMethod == .vBac)
        #expect(existing.babyCount == 2)
    }

    @Test("Save failures propagate to the caller instead of being swallowed")
    func saveThrows() {
        let data = FakeDeliveryData()
        data.errorToThrow = .saveFailed("disk full")
        let model = Make.entryModel(data: data)
        model.upsert(Baby(sex: .female))

        #expect(throws: PersistenceError.saveFailed("disk full")) {
            try model.save()
        }
        #expect(data.loggedDeliveries.isEmpty)
    }

    // MARK: - Baby entry unit round-trip

    @Test("BabyEntry converts metric display values back to stored imperial")
    func babyEntryMetricRoundTrip() {
        var entry = DeliveryEntryModel.BabyEntry(birthday: .now, useMetricUnits: true)
        entry.weight = 3.45    // kg
        entry.height = 48.26   // cm

        let baby = entry.makeBaby(useMetricUnits: true)

        #expect(abs(baby.weight - 3.45 / UnitConversion.ouncesToKilograms) < 0.01)
        #expect(abs(baby.height - 48.26 * UnitConversion.centimetersToInches) < 0.01)
    }
}
