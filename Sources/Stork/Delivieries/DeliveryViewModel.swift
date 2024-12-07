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
    @Published var isSelectingHospital: Bool = false // State for the sheet
    
    var deliveryRepository: DeliveryRepositoryInterface

    // MARK: - Initializer
    @MainActor
    public init(deliveryRepository: DeliveryRepositoryInterface) {
        self.deliveryRepository = deliveryRepository
    }
    
    func getDeliveries(userId: String) {
        Task {
            try await self.deliveries = deliveryRepository.listDeliveries(id: nil, userId: userId, hospitalId: nil, musterId: nil, date: nil, babyCount: nil, deliveryMethod: nil, epiduralUsed: nil)
        }
    }
    
    func submitDelivery(babies: [Baby], profileViewModel: ProfileViewModel, hospitalViewModel: HospitalViewModel) async throws {
        guard let selectedHospital = self.selectedHospital else {
            throw DeliveryError.creationFailed("No hospital selected.")
        }

        let newDelivery = Delivery(
            id: UUID().uuidString,
            userId: profileViewModel.profile.id,
            hospitalId: selectedHospital.id,
            musterId: self.addToMuster ? profileViewModel.profile.musterId : "",
            date: Date(),
            babies: babies,
            babyCount: babies.count,
            deliveryMethod: self.deliveryMethod,
            epiduralUsed: self.epiduralUsed
        )
        
        do {
            try await deliveryRepository.createDelivery(newDelivery)
            self.deliveries.append(newDelivery)

            // Increment hospital values
            hospitalViewModel.updateHospitalWithNewDelivery(hospital: selectedHospital, babyCount: babies.count)
        } catch {
            throw DeliveryError.creationFailed("Failed to submit delivery: \(error.localizedDescription)")
        }
        
        
        // TODO: post-release add to muster timeline if chosen
    }
}
