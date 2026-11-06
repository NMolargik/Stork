//
//  DeliveryEntryModel.swift
//  StorkFeatureDeliveries
//
//  Drives the new/edit delivery form. Holds the editable fields, validates them, manages
//  the tag list through the tag use-cases, and on `save()` routes to `logDelivery` (new,
//  returning any crossed milestone) or `updateDelivery` (edit). Deliveries may be dated
//  any time in the past (`DeliveryDateRule`); the Pro weather snapshot is offered through
//  the `DeliveryWeatherCapturing` seam and gated by `EntitlementProviding`.
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
    /// The attached weather snapshot (Stork Pro), if any.
    public var weather: DeliveryWeather?

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
    private let entitlement: any EntitlementProviding
    private let weatherCapture: (any DeliveryWeatherCapturing)?

    /// - Parameters:
    ///   - entitlement: Decides whether the weather snapshot (Pro) is offered.
    ///   - weatherCapture: The weather source; `nil` hides the snapshot entirely (watch, tests).
    ///   - now: The moment the form opened — the latest date a delivery may have.
    public init(
        existingDelivery: Delivery? = nil,
        logDelivery: any LogDelivery,
        updateDelivery: any UpdateDelivery,
        loadTags: any LoadTags,
        saveTag: any SaveTag,
        entitlement: any EntitlementProviding,
        weatherCapture: (any DeliveryWeatherCapturing)? = nil,
        now: Date = .now
    ) {
        self.existing = existingDelivery
        self.isEditing = existingDelivery != nil
        self.logDeliveryUseCase = logDelivery
        self.updateDeliveryUseCase = updateDelivery
        self.loadTagsUseCase = loadTags
        self.saveTagUseCase = saveTag
        self.entitlement = entitlement
        self.weatherCapture = weatherCapture

        // Anchor the upper bound to the moment the form opens. A bound re-reading `.now`
        // on every access drifts: a date clamped to it lands *outside* the very next
        // check, leaving `canFinish` stuck false.
        let opened = now
        self.dateUpperBound = opened

        if let delivery = existingDelivery {
            date = delivery.date
            deliveryMethod = delivery.deliveryMethod
            epiduralUsed = delivery.epiduralUsed
            babies = delivery.babies ?? []
            notes = delivery.notes ?? ""
            selectedTags = delivery.tags ?? []
            weather = delivery.weather
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

    /// The latest allowed delivery date (the moment the form opened). There is no earliest
    /// date: nurses back-date entries to any past shift. Edits keep their original date.
    public let dateUpperBound: Date

    public var canFinish: Bool {
        !babies.isEmpty && (isEditing || DeliveryDateRule.isAllowed(date, now: dateUpperBound))
    }

    /// Pulls a future-dated entry back to the upper bound; past dates are left alone.
    public func clampDate() {
        guard !isEditing else { return }
        date = DeliveryDateRule.clamped(date, now: dateUpperBound)
    }

    // MARK: - Weather snapshot (Stork Pro)

    public var isProUnlocked: Bool { entitlement.isProUnlocked }

    /// Whether this form offers a weather snapshot at all (a capture source exists).
    public var supportsWeather: Bool { weatherCapture != nil }

    /// Current conditions only describe a recent delivery; older entries can't take a snapshot.
    public var isDateRecentEnoughForWeather: Bool {
        DeliveryDateRule.allowsWeatherSnapshot(date, now: dateUpperBound)
    }

    /// True when tapping "Add Weather" should actually capture (Pro + source + recent date).
    public var canCaptureWeather: Bool {
        supportsWeather && isProUnlocked && isDateRecentEnoughForWeather
    }

    public private(set) var isCapturingWeather = false
    public private(set) var weatherErrorMessage: String?

    /// Requests a one-shot location and the current conditions, attaching them to the form.
    public func captureWeather() async {
        guard canCaptureWeather, let weatherCapture, !isCapturingWeather else { return }
        isCapturingWeather = true
        weatherErrorMessage = nil
        defer { isCapturingWeather = false }
        do {
            weather = try await weatherCapture.captureCurrentWeather()
        } catch {
            weatherErrorMessage = error.localizedDescription
        }
    }

    public func removeWeather() {
        weather = nil
        weatherErrorMessage = nil
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
            existing.weather = weather
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
            delivery.weather = weather
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
