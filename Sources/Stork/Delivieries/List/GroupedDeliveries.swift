//
//  GroupedDeliveries.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/26/25.
//

import Foundation
import StorkModel

struct GroupedDeliveries: Equatable {
    let key: String
    let deliveries: [Delivery]
    
    static func == (lhs: GroupedDeliveries, rhs: GroupedDeliveries) -> Bool {
        lhs.key == rhs.key && lhs.deliveries.map(\.id) == rhs.deliveries.map(\.id)
    }
}
