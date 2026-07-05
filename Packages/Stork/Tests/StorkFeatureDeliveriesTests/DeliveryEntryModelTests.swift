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

    @Test("clampDate pins a new delivery inside the last-3-days window")
    func clampDate() {
        let model = Make.entryModel(data: FakeDeliveryData())
        model.date = Date(timeIntervalSinceNow: -30 * 24 * 3600) // a month ago
        model.clampDate()
        #expect(model.dateRange.contains(model.date))
    }

    @Test("An old delivery being edited stays valid despite the 3-day window")
    func editingBypassesDateWindow() {
        let old = Make.delivery(date: Date(timeIntervalSinceNow: -90 * 24 * 3600))
        let model = Make.entryModel(data: FakeDeliveryData(), existing: old)
        #expect(model.canFinish)
        model.clampDate()   // must be a no-op for edits
        #expect(model.date == old.date)
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
