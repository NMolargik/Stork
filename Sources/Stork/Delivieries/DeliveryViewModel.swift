//
//  DeliveryViewModel.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation
import StorkModel
import SwiftUI

class DeliveryViewModel: ObservableObject {
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
    @Published private(set) var currentDeliveryCount: Int = 0
    
    private var currentDate: Date = Date()
    private var dailyLimit = 8
    private var timer: Timer?
    
    var deliveryRepository: DeliveryRepositoryInterface

    // MARK: - Initializer
    @MainActor
    public init(deliveryRepository: DeliveryRepositoryInterface) {
        self.deliveryRepository = deliveryRepository
        resetCountIfNeeded()
        startDailyResetTimer()
        startNewDelivery()
        groupDeliveriesByMonth()
    }
    
    // MARK: - Delivery Management
    func submitDelivery(profile: Profile, dailyResetManager: DailyResetManager) async throws {
        guard dailyResetManager.canSubmitDelivery() else {
            throw DeliveryError.creationFailed("You have reached the daily limit of 8 deliveries.")
        }
        
        guard self.selectedHospital != nil else {
            throw DeliveryError.creationFailed("No hospital selected.")
        }
        
        newDelivery.babyCount = newDelivery.babies.count
        newDelivery.userFirstName = profile.firstName
        newDelivery.userId = profile.id
        
        if (self.addToMuster) {
            newDelivery.musterId = profile.musterId
        }
        
        print("Delivery: \(newDelivery)")
        
        do {
            newDelivery = try await deliveryRepository.createDelivery(delivery: newDelivery)
            self.deliveries.append(newDelivery)
            
            if (self.addToMuster) {
                self.musterDeliveries.append(newDelivery)
            }
            
            groupDeliveriesByMonth()
            groupMusterDeliveriesByMonth()
            
        } catch {
            throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
        }
        
        // TODO: post-release add to new muster timeline feature if chosen. remember to implement duplicate prevention system
        
        dailyResetManager.incrementDeliveryCount()
        print("New delivery successfully submitted")
        
        
        self.startNewDelivery()
    }
    
    func groupDeliveriesByMonth() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"
        
        let sortedDeliveries = deliveries.sorted(by: { $0.date > $1.date })
        
        var tempGroupedDeliveries: [(key: String, value: [Delivery])] = []
        var currentKey: String? = nil
        var currentGroup: [Delivery] = []
        
        for delivery in sortedDeliveries {
            let key = dateFormatter.string(from: delivery.date)
            if key != currentKey {
                if let existingKey = currentKey {
                    tempGroupedDeliveries.append((key: existingKey, value: currentGroup))
                }

                currentKey = key
                currentGroup = [delivery]
            } else {
                currentGroup.append(delivery)
            }
        }

        if let existingKey = currentKey {
            tempGroupedDeliveries.append((key: existingKey, value: currentGroup))
        }
        
        DispatchQueue.main.async {
            self.groupedDeliveries = tempGroupedDeliveries
            print("Grouped Deliveries Updated")
        }
    }
    
    func groupMusterDeliveriesByMonth() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"
        
        let sortedDeliveries = musterDeliveries.sorted(by: { $0.date > $1.date })
        
        var tempGroupedDeliveries: [(key: String, value: [Delivery])] = []
        var currentKey: String? = nil
        var currentGroup: [Delivery] = []
        
        for delivery in sortedDeliveries {
            let key = dateFormatter.string(from: delivery.date)
            if key != currentKey {
                if let existingKey = currentKey {
                    tempGroupedDeliveries.append((key: existingKey, value: currentGroup))
                }

                currentKey = key
                currentGroup = [delivery]
            } else {
                currentGroup.append(delivery)
            }
        }

        if let existingKey = currentKey {
            tempGroupedDeliveries.append((key: existingKey, value: currentGroup))
        }
        
        DispatchQueue.main.async {
            self.groupedMusterDeliveries = tempGroupedDeliveries
            print("Muster Grouped Deliveries Updated")
        }
    }
    
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
            deliveryMethod: DeliveryMethod.vaginal,
            epiduralUsed: false
        )
    }
    
    func addBaby() {
        let newBaby = Baby(deliveryId: UUID().uuidString, nurseCatch: false, sex: Sex.male)
        newDelivery.babies.append(newBaby)
    }
    
    func getUserDeliveries(profile: Profile) async throws {
        do {
            let fetchedDeliveries = try await deliveryRepository.listDeliveries(
                userId: profile.id,
                userFirstName: nil,
                hospitalId: nil,
                hospitalName: nil,
                musterId: nil,
                date: nil,
                babyCount: nil,
                deliveryMethod: nil,
                epiduralUsed: nil
            )
            await MainActor.run {
                self.deliveries = fetchedDeliveries
                groupDeliveriesByMonth()
            }
        } catch {
            throw error
        }
    }
    
    func getMusterDeliveries(muster: Muster) async throws {
        do {
            print("GETTING MUSTER DELIVERIES")
            
            let fetchedDeliveries = try await deliveryRepository.listDeliveries(
                userId: nil,
                userFirstName: nil,
                hospitalId: nil,
                hospitalName: nil,
                musterId: muster.id,
                date: nil,
                babyCount: nil,
                deliveryMethod: nil,
                epiduralUsed: nil
            )
            
            await MainActor.run {
                self.musterDeliveries = fetchedDeliveries
                groupMusterDeliveriesByMonth()
            }
        }
    }
    
    func searchForDuplicates(musterId: String) async -> [Delivery] {
        self.isWorking = true
        
        do {
            let duplicates = try await deliveryRepository.listDeliveries(userId: nil, userFirstName: nil, hospitalId: selectedHospital?.id, hospitalName: nil, musterId: musterId, date: self.currentDate, babyCount: self.selectedHospital?.babyCount, deliveryMethod: self.deliveryMethod, epiduralUsed: self.epiduralUsed)
            
            self.isWorking = false
            return duplicates
        } catch {
            self.isWorking = false
            return []
        }
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
        // Get the current date and calendar
        let now = Date()
        let calendar = Calendar.current

        // Extract components for today
        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: now)

        // Manually create the next reset time at 12:01 AM
        var resetComponents = currentDateComponents
        resetComponents.hour = 0
        resetComponents.minute = 1
        resetComponents.second = 0

        // Get the reset date
        guard let resetDate = calendar.date(from: resetComponents) else { return }

        // If the reset time is in the past for today, move to tomorrow
        let adjustedResetDate = resetDate > now ? resetDate : calendar.date(byAdding: .day, value: 1, to: resetDate)!

        // Calculate the time interval
        let timeInterval = adjustedResetDate.timeIntervalSince(now)

        // Schedule the timer
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.resetDailyLimit()
            self?.startDailyResetTimer() // Schedule the next reset
        }
    }
    
    func additionPropertiesChanged() {
        self.canSubmitDelivery = !newDelivery.babies.isEmpty && selectedHospital != nil
        print(canSubmitDelivery)
    }
    
    private func resetDailyLimit() {
        currentDeliveryCount = 0
        currentDate = Date()
    }
}
