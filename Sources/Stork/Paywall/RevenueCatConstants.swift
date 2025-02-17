//
//  RevenueCatConstants.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/7/25.
//

import Foundation
import SwiftUI

struct StoreConstants {
    #if SKIP
    static let apiKey = "goog_wqAoIhKYjQVhKmaOMDLqZzldfIO"
    #else
    static let apiKey = "appl_IJaUJSFJvADbJAclPsSrsHInYKP"
    #endif
    
    static let entitlementID = "StorkAnnual"
    static let packageID = "$rc_annual"
    
}

