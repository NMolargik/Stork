//
//  File.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/7/25.
//

import Foundation
import SwiftUI

struct StoreConstants {
    
    #if SKIP
    static let apiKey = "GOOGLE_KEY"
    #else
    static let apiKey = "APPLE_KEY"
    #endif
    
    static let entitlementID = "Premium"
    
}
