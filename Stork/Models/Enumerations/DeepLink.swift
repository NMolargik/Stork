//
//  DeepLink.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation

/// Deep link actions that can be triggered from widgets or external URLs
enum DeepLink: Equatable {
    case newDelivery
    case home
    case deliveries
    case weeklyDeliveries
    case settings
}
