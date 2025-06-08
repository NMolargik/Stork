//
//  RevenueCatConstants.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/7/25.
//

import SkipFoundation
import SwiftUI

struct StoreConstants {
    #if SKIP
    static let apiKey = "goog_KGgJYlofTBhUUOkHTnuUbSrcgWi"
    #else
    static let apiKey = "appl_IJaUJSFJvADbJAclPsSrsHInYKP"
    #endif
    
    static let entitlementID = "Stork Monthly"
    static let packageID = "$rc_monthly"
}

