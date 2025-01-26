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
    @Published var groupedDeliveries: [GroupedDeliveries] = []
    @Published var groupedMusterDeliveries: [GroupedDeliveries] = []

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
    var lastFetchedEndDate: Date?
    @Published var hasMorePages: Bool = true

    // MARK: - Repository
    var deliveryRepository: DeliveryRepositoryInterface

    // MARK: - Initializer
    public init(deliveryRepository: DeliveryRepositoryInterface) {
        self.deliveryRepository = deliveryRepository
        
        // Daily limit logic
        resetCountIfNeeded()
        startDailyResetTimer()
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
            do {
                newDelivery = try await deliveryRepository.createDelivery(delivery: newDelivery)
                deliveries.append(newDelivery)
                if addToMuster {
                    musterDeliveries.append(newDelivery)
                }

                DispatchQueue.main.async {
                    self.groupDeliveries()
                    self.groupMusterDeliveries()
                }
            } catch {
                throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
            }
        } catch {
            throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
        }
        
        dailyResetManager.incrementDeliveryCount()
        print("New delivery successfully submitted.")
        
        // Reset for the next new delivery
        DispatchQueue.main.async {
            self.startNewDelivery()
        }
    }
    
    // MARK: - Fetch Next Page of Deliveries
    func fetchNextDeliveries(profile: Profile) async throws {
        guard hasMorePages else {
            print("No more pages to load.")
            return
        }

        isWorking = true

        guard let (startDate, endDate) = calculateNextPageDates() else {
            print("Could not calculate date range for page \(currentPage + 1).")
            isWorking = false
            return
        }

        print("Fetching deliveries from Firestore...")
        print("Query Start Date: \(startDate)")
        print("Query End Date: \(endDate)")
        print("User ID: \(profile.id)")

        do {
            let newDeliveries = try await deliveryRepository.listDeliveries(
                userId: profile.id,
                userFirstName: nil,
                hospitalId: nil,
                hospitalName: nil,
                musterId: nil,
                date: nil,
                babyCount: nil,
                deliveryMethod: nil,
                epiduralUsed: nil,
                startDate: startDate,
                endDate: endDate
            )
            
            if !newDeliveries.isEmpty {
                self.deliveries.append(contentsOf: newDeliveries)
                lastFetchedEndDate = endDate
                currentPage += 1
                print("Updated lastFetchedEndDate to \(lastFetchedEndDate!) for next pagination step.")
            } else {
                hasMorePages = false  // ✅ Stop paginating if no more data
                print("No more deliveries found. Stopping pagination.")
            }
            
            groupDeliveries()
            print("Fetched \(newDeliveries.count) deliveries.")
        } catch {
            print("Error fetching deliveries: \(error.localizedDescription)")
            isWorking = false
        }
        
        isWorking = false
    }

    // MARK: - Fetch Muster Deliveries (Last 6 Months Only)
    func fetchMusterDeliveries(muster: Muster) async throws {
        isWorking = true

        guard let (startDate, endDate) = calculateInitialDateRange() else {
            print("Could not calculate date range for muster deliveries.")
            isWorking = false
            return
        }
        
        print("Fetching muster deliveries from Firestore...")
        print("Muster Query Start Date: \(startDate)")
        print("Muster Query End Date: \(endDate)")


        do {
            let newMusterDeliveries = try await deliveryRepository.listDeliveries(
                userId: nil,
                userFirstName: nil,
                hospitalId: nil,
                hospitalName: nil,
                musterId: muster.id,
                date: nil,
                babyCount: nil,
                deliveryMethod: nil,
                epiduralUsed: nil,
                startDate: startDate,
                endDate: endDate
            )
            
            self.musterDeliveries = newMusterDeliveries
            groupMusterDeliveries()
            print("Fetched \(musterDeliveries.count) muster deliveries.")
        } catch {
            isWorking = false
            print("Error fetching muster deliveries: \(error.localizedDescription)")
        }
        
        isWorking = false
    }
    
    // MARK: - Date Calculation for Pagination
    /// **Initial Range:** First day of the upcoming month to the first day of 6 months ago.
    private func calculateInitialDateRange() -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the first day of the upcoming month (endDate)
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let firstOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            return nil
        }
        
        // Calculate the first day of 6 months ago (startDate)
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: firstOfNextMonth),
              let firstOfSixMonthsAgo = calendar.date(from: calendar.dateComponents([.year, .month], from: sixMonthsAgo)) else {
            return nil
        }

        return (firstOfSixMonthsAgo, firstOfNextMonth)
    }

    /// **Next Page:** First request fetches from upcoming month to 6 months ago.
    /// Subsequent pages shift back by 6 months.
    private func calculateNextPageDates() -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current

        // If this is the first request, use the initial date range.
        if lastFetchedEndDate == nil {
            return calculateInitialDateRange()
        }

        guard let lastEndDate = lastFetchedEndDate else {
            return nil
        }

        // Calculate new endDate (first day of the month, 6 months before last endDate)
        guard let newEndDate = calendar.date(byAdding: .month, value: -6, to: lastEndDate),
              let firstOfNewEndMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newEndDate)) else {
            return nil
        }

        // Calculate new startDate (first day of the month, 6 months before newEndDate)
        guard let newStartDate = calendar.date(byAdding: .month, value: -6, to: firstOfNewEndMonth),
              let firstOfNewStartMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newStartDate)) else {
            return nil
        }

        return (firstOfNewStartMonth, firstOfNewEndMonth)
    }
    
    // MARK: - Searching for Duplicates
    /// Searches for possible duplicate deliveries in the last 6 months.
    /// The search is scoped to a specific `musterId` and the selected hospital.
    func searchForDuplicates(musterId: String) async -> [Delivery] {
        isWorking = true
        defer { isWorking = false }

        guard let (startDate, endDate) = calculateInitialDateRange() else {
            print("Could not calculate date range for duplicate search.")
            return []
        }

        do {
            return try await deliveryRepository.listDeliveries(
                userId: nil,
                userFirstName: nil,
                hospitalId: selectedHospital?.id,
                hospitalName: nil,
                musterId: musterId,
                date: currentDate,  // Searching for possible duplicates on the same date
                babyCount: selectedHospital?.babyCount,
                deliveryMethod: deliveryMethod,
                epiduralUsed: epiduralUsed,
                startDate: startDate,  // Use last 6 months as the default range
                endDate: endDate
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
        print("⚡ Before Updating groupedMusterDeliveries: \(groupedMusterDeliveries.count) groups")

        guard !musterDeliveries.isEmpty else {
            print("🚨 Muster deliveries are empty. Skipping grouping to prevent crash.")
            return
        }

        let safeCopy = musterDeliveries // ✅ Prevent mutation during iteration

        DispatchQueue.main.async {
            let newGroups = self.groupDeliveriesByMonth(safeCopy)
            
            // ✅ Prevent invalid array updates
            guard !newGroups.isEmpty else {
                print("🚨 No muster deliveries were grouped. Skipping update.")
                return
            }

            self.groupedMusterDeliveries = newGroups
            print("✅ After Updating groupedMusterDeliveries: \(self.groupedMusterDeliveries.count) groups")
        }
    }
    
    private func groupDeliveriesByMonth(_ deliveries: [Delivery]) -> [GroupedDeliveries] {
        guard !deliveries.isEmpty else {
            print("🚨 groupDeliveriesByMonth received an empty list!")
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"

        let sorted = deliveries.sorted { $0.date > $1.date }
        
        // ✅ Ensure sorted list isn't empty before proceeding
        guard !sorted.isEmpty else {
            print("🚨 Sorted deliveries list is empty. Skipping grouping.")
            return []
        }

        print("✅ Sorted \(sorted.count) deliveries by date.")

        var results: [GroupedDeliveries] = []
        var currentKey: String?
        var currentGroup: [Delivery] = []

        for delivery in sorted {
            let key = dateFormatter.string(from: delivery.date)

            if key != currentKey {
                if let existingKey = currentKey, !currentGroup.isEmpty {
                    results.append(GroupedDeliveries(key: existingKey, deliveries: currentGroup))
                }
                currentKey = key
                currentGroup = [delivery]
            } else {
                currentGroup.append(delivery)
            }
        }

        // ✅ Only append if there's valid data
        if let existingKey = currentKey, !currentGroup.isEmpty {
            results.append(GroupedDeliveries(key: existingKey, deliveries: currentGroup))
        }

        print("✅ Grouped deliveries into \(results.count) groups.")
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
            nicuStay: false,
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
