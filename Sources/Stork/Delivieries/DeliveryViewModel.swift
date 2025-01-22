//
//  DeliveryViewModel.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation
import StorkModel
import SwiftUI

@MainActor
class DeliveryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var deliveries: [Delivery] = []
    @Published var musterDeliveries: [Delivery] = []
    @Published var groupedDeliveries: [(key: String, value: [Delivery])] = []
    @Published var groupedMusterDeliveries: [(key: String, value: [Delivery])] = []

    @Published var newDelivery: Delivery = Delivery(sample: true)
    @Published var epiduralUsed: Bool = false
    @Published var deliveryMethod: DeliveryMethod = .vaginal
    @Published var addToMuster: Bool = false
    @Published var selectedHospital: Hospital? = nil
    @Published var possibleDuplicates: [Delivery] = []
    @Published var isWorking: Bool = false
    @Published var isSelectingHospital: Bool = false
    @Published var canSubmitDelivery: Bool = false

    // MARK: - Daily Limit Logic
    @Published private(set) var currentDeliveryCount: Int = 0
    private var currentDate: Date = Date()
    private var dailyLimit = 8
    private var timer: Timer?

    // MARK: - Pagination
    /// Each page represents a 6-month interval from the current date, going backward.
    /// page 0 = last 6 months, page 1 = 6–12 months ago, etc.
    @Published var currentPage: Int = 0
    private let monthsPerPage: Int = 6

    // MARK: - Repository
    var deliveryRepository: DeliveryRepositoryInterface

    // MARK: - Initializer
    public init(deliveryRepository: DeliveryRepositoryInterface) {
        self.deliveryRepository = deliveryRepository
        
        // Daily limit logic
        resetCountIfNeeded()
        startDailyResetTimer()

        // Start a fresh new delivery
        startNewDelivery()
    }

    // MARK: - Submit Delivery
    func submitDelivery(profile: Profile, dailyResetManager: DailyResetManager) async throws {
        guard dailyResetManager.canSubmitDelivery() else {
            throw DeliveryError.creationFailed("You have reached the daily limit of \(dailyLimit) deliveries.")
        }
        guard selectedHospital != nil else {
            throw DeliveryError.creationFailed("No hospital selected.")
        }
        
        // Basic newDelivery setup
        newDelivery.babyCount = newDelivery.babies.count
        newDelivery.userFirstName = profile.firstName
        newDelivery.userId = profile.id
        if addToMuster { newDelivery.musterId = profile.musterId }

        // Create Delivery in Repository
        do {
            newDelivery = try await deliveryRepository.createDelivery(delivery: newDelivery)
            deliveries.append(newDelivery)
            if addToMuster {
                musterDeliveries.append(newDelivery)
            }
            groupDeliveries()
            groupMusterDeliveries()
        } catch {
            throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
        }
        
        dailyResetManager.incrementDeliveryCount()
        print("New delivery successfully submitted.")
        
        // Reset for the next new delivery
        startNewDelivery()
    }
    
    // MARK: - Paginated Fetch for User Deliveries
    /// Loads deliveries for this user, using 6-month page ranges.
    /// page 0 = last 6 months, page 1 = 6–12 months ago, etc.
    /// - Throws: DeliveryError or other if fetching fails.
    func fetchDeliveriesForCurrentPage(profile: Profile) async throws {
        isWorking = true
        defer { isWorking = false }

        guard let (startAt, endAt) = pageDates(for: currentPage) else {
            print("Could not calculate date range for page \(currentPage).")
            return
        }

        // Provide all required parameters, including startAt/endAt
        deliveries = try await deliveryRepository.listDeliveries(
            userId: profile.id,
            userFirstName: nil,
            hospitalId: nil,
            hospitalName: nil,
            musterId: nil,
            date: nil,
            babyCount: nil,
            deliveryMethod: nil,
            epiduralUsed: nil,
            startAt: startAt,
            endAt: endAt
        )

        groupDeliveries()
        print("Fetched \(deliveries.count) user deliveries for page \(currentPage).")
    }

    // MARK: - Paginated Fetch for Muster Deliveries
    /// Loads muster deliveries for this muster, also using 6-month page ranges.
    /// - Throws: DeliveryError or other if fetching fails.
    func fetchMusterDeliveriesForCurrentPage(muster: Muster) async throws {
        isWorking = true
        defer { isWorking = false }

        guard let (startAt, endAt) = pageDates(for: currentPage) else {
            print("Could not calculate date range for muster page \(currentPage).")
            return
        }

        musterDeliveries = try await deliveryRepository.listDeliveries(
            userId: nil,
            userFirstName: nil,
            hospitalId: nil,
            hospitalName: nil,
            musterId: muster.id,
            date: nil,
            babyCount: nil,
            deliveryMethod: nil,
            epiduralUsed: nil,
            startAt: startAt,
            endAt: endAt
        )

        groupMusterDeliveries()
        print("Fetched \(musterDeliveries.count) muster deliveries for page \(currentPage).")
    }

    /// Computes (startAt, endAt) for the requested page.
    private func pageDates(for page: Int) -> (Date, Date)? {
        let now = Date()

        guard let endAt = Calendar.current.date(byAdding: .month, value: -monthsPerPage * page, to: now),
              let startAt = Calendar.current.date(byAdding: .month, value: -monthsPerPage * (page + 1), to: now)
        else {
            return nil
        }

        // We want deliveries in [startAt, endAt).
        return (startAt, endAt)
    }
    
    // MARK: - Searching for Duplicates
    /// Example: If you still want to pass explicit startAt/endAt for duplicates, do so here.
    /// For now, we just pass nil to the new pagination parameters to indicate "full range" if you want:
    func searchForDuplicates(musterId: String) async -> [Delivery] {
        isWorking = true
        defer { isWorking = false }

        do {
            // Minimal or no pagination logic? Just pass explicit nil for startAt/endAt if you want everything.
            return try await deliveryRepository.listDeliveries(
                userId: nil,
                userFirstName: nil,
                hospitalId: selectedHospital?.id,
                hospitalName: nil,
                musterId: musterId,
                date: currentDate,
                babyCount: selectedHospital?.babyCount,
                deliveryMethod: deliveryMethod,
                epiduralUsed: epiduralUsed,
                startAt: nil, // or define a date range if you prefer
                endAt: nil
            )
        } catch {
            print("Error searching for duplicates: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Grouping Logic
    func groupDeliveries() {
        self.groupedDeliveries = groupDeliveriesByMonth(deliveries)
        print("Grouped Deliveries Updated.")
    }

    func groupMusterDeliveries() {
        self.groupedMusterDeliveries = groupDeliveriesByMonth(musterDeliveries)
        print("Muster Grouped Deliveries Updated.")
    }

    private func groupDeliveriesByMonth(_ deliveries: [Delivery]) -> [(key: String, value: [Delivery])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"

        let sorted = deliveries.sorted { $0.date > $1.date }
        
        var results: [(String, [Delivery])] = []
        var currentKey: String?
        var currentGroup: [Delivery] = []

        for delivery in sorted {
            let key = dateFormatter.string(from: delivery.date)
            if key != currentKey {
                if let existingKey = currentKey {
                    results.append((existingKey, currentGroup))
                }
                currentKey = key
                currentGroup = [delivery]
            } else {
                currentGroup.append(delivery)
            }
        }
        
        if let existingKey = currentKey {
            results.append((existingKey, currentGroup))
        }
        return results
    }

    // MARK: - New Delivery Logic
    func startNewDelivery() {
        self.newDelivery = Delivery(
            id: UUID().uuidString,
            userId: "",
            userFirstName: "",
            hospitalId: "",
            hospitalName: "",
            musterId: "",
            date: Date(),
            babies: [],
            babyCount: 0,
            deliveryMethod: .vaginal,
            epiduralUsed: false
        )
    }

    func addBaby() {
        let newBaby = Baby(
            deliveryId: UUID().uuidString,
            nurseCatch: false,
            sex: .male
        )
        newDelivery.babies.append(newBaby)
    }

    // MARK: - UI State Management
    func additionPropertiesChanged() {
        canSubmitDelivery = !newDelivery.babies.isEmpty && selectedHospital != nil
        print(canSubmitDelivery)
    }

    // MARK: - Daily Limit Handling
    private func resetCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: Date()) {
            currentDate = Date()
            currentDeliveryCount = 0
        }
    }
    
    private func startDailyResetTimer() {
        timer?.invalidate()
        
        let now = Date()
        let calendar = Calendar.current

        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        var resetComponents = currentDateComponents
        resetComponents.hour = 0
        resetComponents.minute = 1
        resetComponents.second = 0

        guard let resetDate = calendar.date(from: resetComponents) else { return }
        let adjustedResetDate = (resetDate > now)
            ? resetDate
            : calendar.date(byAdding: .day, value: 1, to: resetDate)!

        let timeInterval = adjustedResetDate.timeIntervalSince(now)

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.resetDailyLimit()
                    self?.startDailyResetTimer()
                }
            }
        }
    }

    private func resetDailyLimit() {
        currentDeliveryCount = 0
        currentDate = Date()
        print("Daily Limit reset to 0.")
    }

    // MARK: - Delivery Lookup
    func findDelivery(by id: String) -> Binding<Delivery>? {
        guard let index = deliveries.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.deliveries[index] },
            set: { self.deliveries[index] = $0 }
        )
    }
}
