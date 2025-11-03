//
//  InsightManager.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

@Observable
class InsightManager {
    private let deliveryManager: DeliveryManager
    
    // MARK: - Init
    init(
        deliveryManager: DeliveryManager
    ) {
        self.deliveryManager = deliveryManager
    }
}
