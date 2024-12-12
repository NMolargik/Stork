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
    @Published var epiduralUsed: Bool = false
    @Published var deliveryMethod: DeliveryMethod = .vaginal
    @Published var addToMuster: Bool = false
    @Published var selectedHospital: Hospital? = nil
    @Published var submitEnabled: Bool = false
    @Published var isSelectingHospital: Bool = false
    @Published var possibleDuplicates: [Delivery] = []
    @Published var searchingForDuplicates: Bool = false
    @Published var newBabies: [Baby] = []
    @Published var isSubmitting: Bool = false
    
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
    }
    
    deinit {
        timer?.invalidate()
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
    
    private func resetDailyLimit() {
        currentDeliveryCount = 0
        currentDate = Date()
    }
    
    // MARK: - Delivery Management
    
    func submitDelivery(babies: [Baby], profileViewModel: ProfileViewModel, hospitalViewModel: HospitalViewModel) async throws {
        // Enforce the daily limit
        
        
        //TODO: query Muster is applicable to make sure user is still a member of it
        guard currentDeliveryCount < dailyLimit else {
            throw DeliveryError.creationFailed("You have reached the daily limit of \(dailyLimit) deliveries.")
        }
        
        guard let selectedHospital = self.selectedHospital else {
            throw DeliveryError.creationFailed("No hospital selected.")
        }

        let newDelivery = Delivery(
            id: UUID().uuidString,
            userId: profileViewModel.profile.id,
            userFirstName: profileViewModel.profile.firstName,
            hospitalId: selectedHospital.id,
            musterId: self.addToMuster ? profileViewModel.profile.musterId : "",
            date: Date(),
            babies: babies,
            babyCount: babies.count,
            deliveryMethod: self.deliveryMethod,
            epiduralUsed: self.epiduralUsed
        )
        
        do {
            let delivery = try await deliveryRepository.createDelivery(newDelivery)
            self.deliveries.append(delivery)
            currentDeliveryCount += 1
            
            hospitalViewModel.updateHospitalWithNewDelivery(hospital: selectedHospital, babyCount: babies.count)
        } catch {
            throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
        }
        
        // TODO: post-release add to new muster timeline feature if chosen. remember to implement duplicate prevention system
        
        self.resetDelivery()
    }
    
    func getDeliveries(userId: String) {
        Task { @MainActor in
            self.deliveries = try await deliveryRepository.listDeliveries(
                userId: userId,
                userFirstName: nil,
                hospitalId: nil,
                musterId: nil,
                date: nil,
                babyCount: nil,
                deliveryMethod: nil,
                epiduralUsed: nil
            )
        }
    }
    
    func searchForDuplicates(musterId: String) async -> [Delivery] {
        self.submitEnabled = false
        self.searchingForDuplicates = true
        
        do {
            let duplicates = try await deliveryRepository.listDeliveries(userId: nil, userFirstName: nil, hospitalId: selectedHospital?.id, musterId: musterId, date: self.currentDate, babyCount: self.selectedHospital?.babyCount, deliveryMethod: self.deliveryMethod, epiduralUsed: self.epiduralUsed)
            
            self.submitEnabled = true
            self.searchingForDuplicates = false
            return duplicates
        } catch {
            self.submitEnabled = true
            self.searchingForDuplicates = false
            return []
        }
    }
    
    func resetDelivery() {
        self.selectedHospital = nil
        self.addToMuster = false
        self.deliveryMethod = .vaginal
        self.epiduralUsed = false
        self.newBabies = []
    }

}
