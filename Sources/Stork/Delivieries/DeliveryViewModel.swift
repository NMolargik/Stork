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
    
    var deliveryRepository: DeliveryRepositoryInterface

    // MARK: - Initializer
    @MainActor
    public init(deliveryRepository: DeliveryRepositoryInterface) {
        self.deliveryRepository = deliveryRepository
        
        Task {
            try await self.deliveries = deliveryRepository.listDeliveries(id: nil, hospitalId: nil, musterId: nil, date: nil, babyCount: nil, deliveryMethod: nil, epiduralUsed: nil)
        }
        
        //self.fetchUsersDeliveries
    }
    
    
    
    
    
}
