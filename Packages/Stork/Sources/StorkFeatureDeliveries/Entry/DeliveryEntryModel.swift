//
//  DeliveryEntryModel.swift
//  StorkFeatureDeliveries
//
//  Drives the new/edit delivery form. Holds the editable fields, validates them, manages
//  the tag list through the tag use-cases, and on `save()` routes to `logDelivery` (new,
//  returning any crossed milestone) or `updateDelivery` (edit).
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class DeliveryEntryModel {

    // Editable fields
    public var date: Date
    public var deliveryMethod: DeliveryMethod
    public var epiduralUsed: Bool
    public var babies: [Baby]
    public var notes: String
    public var selectedTags: [DeliveryTag]

    // Sheet presentation
    public var showingBabySheet = false
    public var showingTagSheet = false

    // Tag picker data
    public private(set) var availableTags: [DeliveryTag] = []

    /// Failures from tag operations (form-side, non-blocking). Save failures throw.
    public private(set) var lastError: PersistenceError?

    public let isEditing: Bool
    private let existing: Delivery?

    private let logDeliveryUseCase: any LogDelivery
    private let updateDeliveryUseCase: any UpdateDelivery
    private let loadTagsUseCase: any LoadTags
    private let saveTagUseCase: any SaveTag

    public init(
        existingDelivery: Delivery? = nil,
        logDelivery: any LogDelivery,
        updateDelivery: any UpdateDelivery,
        loadTags: any LoadTags,
        saveTag: any SaveTag
    ) {
        self.existing = existingDelivery
        self.isEditing = existingDelivery != nil
        self.logDeliveryUseCase = logDelivery
        self.updateDeliveryUseCase = updateDelivery
        self.loadTagsUseCase = loadTags
        self.saveTagUseCase = saveTag

        // Anchor the allowed window to the moment the form opens. A computed range
        // re-reading `.now` on every access drifts: a date clamped to the lower bound
        // lands *outside* the very next range, leaving `canFinish` stuck false.
        let opened = Date.now
        let lower = Calendar.current.date(byAdding: .day, value: -3, to: opened) ?? opened
        self.dateRange = lower...opened

        if let delivery = existingDelivery {
            date = delivery.date
            deliveryMethod = delivery.deliveryMethod
            epiduralUsed = delivery.epiduralUsed
            babies = delivery.babies ?? []
            notes = delivery.notes ?? ""
            selectedTags = delivery.tags ?? []
        } else {
            date = opened   // the range's upper bound, so a fresh form always validates
            deliveryMethod = .vaginal
            epiduralUsed = true
            babies = []
            notes = ""
            selectedTags = []
        }
    }

    // MARK: - Validation

    /// New deliveries must fall within the 3 days before the form was opened (edits keep
    /// their original date). Fixed at init so clamping and validation agree.
    public let dateRange: ClosedRange<Date>

    public var canFinish: Bool {
        !babies.isEmpty && (isEditing || dateRange.contains(date))
    }

    public func clampDate() {
        guard !isEditing else { return }
        if date < dateRange.lowerBound { date = dateRange.lowerBound }
        else if date > dateRange.upperBound { date = dateRange.upperBound }
    }

    // MARK: - Babies

    public func removeBaby(id: UUID) {
        babies.removeAll { $0.id == id }
    }

    public func upsert(_ baby: Baby) {
        if let index = babies.firstIndex(where: { $0.id == baby.id }) {
            babies[index] = baby
        } else {
            babies.append(baby)
        }
    }

    // MARK: - Tags

    public func loadTags() {
        availableTags = (try? loadTagsUseCase()) ?? []
    }

    public func toggleTag(_ tag: DeliveryTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    public func removeTag(id: UUID) {
        selectedTags.removeAll { $0.id == id }
    }

    /// Creates a tag if needed, then selects it. A name match (case-insensitive) reuses
    /// the existing tag instead of duplicating.
    public func createAndSelectTag(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = availableTags.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            if !selectedTags.contains(where: { $0.id == existing.id }) { selectedTags.append(existing) }
            return
        }

        let tag = DeliveryTag(name: trimmed, colorHex: colorHex)
        do {
            try saveTagUseCase(tag, isNew: true)
            availableTags.append(tag)
            selectedTags.append(tag)
            lastError = nil
        } catch {
            // Don't select a tag that never persisted.
            lastError = error
        }
    }

    // MARK: - Save

    /// Persists the form, throwing on failure so the UI can keep the sheet open and
    /// explain. Returns a crossed career milestone for new deliveries.
    @discardableResult
    public func save() throws(PersistenceError) -> MilestoneCelebration? {
        let trimmedNotes = notes.isEmpty ? nil : notes
        if let existing {
            existing.date = date
            existing.deliveryMethod = deliveryMethod
            existing.epiduralUsed = epiduralUsed
            existing.babyCount = babies.count
            existing.notes = trimmedNotes
            existing.tags = selectedTags
            existing.babies = babies
            try updateDeliveryUseCase(existing)
            return nil
        } else {
            let delivery = Delivery(
                date: date,
                babies: babies,
                babyCount: babies.count,
                deliveryMethod: deliveryMethod,
                epiduralUsed: epiduralUsed,
                notes: trimmedNotes,
                tags: selectedTags
            )
            return try logDeliveryUseCase(delivery)
        }
    }

    // MARK: - Baby entry helper

    /// Form-side representation of a baby, with unit-aware display values.
    public struct BabyEntry {
        public var id: UUID?
        public var sex: Sex = .male
        public var weight: Double
        public var height: Double
        public var nurseCatch: Bool = false
        public var nicuStay: Bool = false
        public var birthday: Date

        public init(birthday: Date, baby: Baby? = nil, useMetricUnits: Bool = false) {
            self.birthday = birthday
            if let baby {
                id = baby.id
                sex = baby.sex
                weight = useMetricUnits ? baby.weight * UnitConversion.ouncesToKilograms : baby.weight
                height = useMetricUnits ? baby.height * UnitConversion.inchesToCentimeters : baby.height
                nurseCatch = baby.nurseCatch
                nicuStay = baby.nicuStay
            } else {
                weight = useMetricUnits ? 3.45 : 121.6   // ~7 lb 9.6 oz
                height = useMetricUnits ? 48.26 : 19.0    // ~19 in
            }
        }

        /// Builds the `Baby` model, converting display units back to stored imperial.
        public func makeBaby(useMetricUnits: Bool) -> Baby {
            let weightOunces = useMetricUnits ? weight / UnitConversion.ouncesToKilograms : weight
            let heightInches = useMetricUnits ? height * UnitConversion.centimetersToInches : height
            let baby = Baby()
            baby.id = id ?? UUID()
            baby.sex = sex
            baby.weight = weightOunces
            baby.height = heightInches
            baby.nicuStay = nicuStay
            baby.nurseCatch = nurseCatch
            baby.birthday = birthday
            return baby
        }

        public var isValid: Bool { weight > 0 && height > 0 }
    }
}
