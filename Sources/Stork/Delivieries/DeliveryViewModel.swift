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
    @AppStorage("dailyDeliveryCount") private var dailyDeliveryCount: Int = 0
    
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
    @Published var isFetchingDeliveries: Bool = false
    @Published var isFetchingMusterDeliveries: Bool = false

    // MARK: - Daily Limit Logic
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

        // Start a fresh new delivery
        startNewDelivery()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func reset() {
        self.deliveries = []
        self.musterDeliveries = []
        self.groupedDeliveries = []
        self.groupedMusterDeliveries = []
        self.dailyDeliveryCount = 0
        self.currentPage = 0
        self.lastFetchedEndDate = nil
        self.hasMorePages = true

        // Invalidate and clear the timer to stop any pending resets.
        self.timer?.invalidate()
        self.timer = nil

        // Reset the current date so that the daily limit is tied to a fresh day.
        self.currentDate = Date()

        // Optionally, restart the daily reset timer.
        startDailyResetTimer()
        dailyDeliveryCount = 0
    }

    // MARK: - Submit Delivery
    func submitDelivery(profile: Profile, dailyResetUtility: DailyResetUtility) async throws {
        guard dailyResetUtility.canSubmitDelivery() else {
            throw DeliveryError.limitReached("You have reached the daily limit of \(dailyLimit) deliveries.")
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
        
        dailyResetUtility.incrementDeliveryCount()
        print("New delivery successfully submitted.")
        
        // Reset for the next new delivery
        startNewDelivery()
    }
    
    // MARK: - Fetch Next Page of Deliveries
    func fetchNextDeliveries(profile: Profile) async throws {
        guard hasMorePages, !isFetchingDeliveries else {
            print("No more pages to load or already collecting")
            return
        }
        
        isFetchingDeliveries = true
        defer { isFetchingDeliveries = false }
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
        guard !isFetchingMusterDeliveries else {
            print("Already fetching muster deliveries, skipping duplicate request.")
            return
        }
        
        isFetchingMusterDeliveries = true
        defer { isFetchingMusterDeliveries = false }
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
    
    func refreshMusterDeliveries() {
        let cachedDeliveries = self.groupedMusterDeliveries
        self.groupedMusterDeliveries = []
        self.groupedMusterDeliveries = cachedDeliveries
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
            nicuStay: false,
            sex: .male
        )
        newDelivery.babies.append(newBaby)
        objectWillChange.send() // Ensure UI updates

    }

    // MARK: - UI State Management
    func additionPropertiesChanged() {
        canSubmitDelivery = !newDelivery.babies.isEmpty && selectedHospital != nil
    }

    // MARK: - Daily Limit Handling
    private func resetCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: Date()) {
            currentDate = Date()
            dailyDeliveryCount = 0
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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                guard let self = self else { return }

                Task {
                    await self.resetDailyLimit()
                    await self.startDailyResetTimer()
                }
            }
        }
    }

    private func resetDailyLimit() {
        dailyDeliveryCount = 0
        currentDate = Date()
        print("Daily Limit reset to 0.")
    }

    // MARK: - Delivery Lookup
    func findDelivery(by id: String) -> Binding<Delivery>? {
        // Check that a delivery with this id exists at the moment.
        guard deliveries.contains(where: { $0.id == id }) else { return nil }
        
        return Binding<Delivery>(
            get: { [weak self] in
                guard let self = self,
                      let index = self.deliveries.firstIndex(where: { $0.id == id }) else {
                    fatalError("Delivery not found when getting binding for id \(id)")
                }
                return self.deliveries[index]
            },
            set: { [weak self] newDelivery in
                guard let self = self,
                      let index = self.deliveries.firstIndex(where: { $0.id == id }) else {
                    return
                }
                self.deliveries[index] = newDelivery
            }
        )
    }
}
