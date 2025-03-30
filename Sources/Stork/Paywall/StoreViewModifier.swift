//
//  StoreViewModifier.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/7/25.
//

import SkipFoundation
import SwiftUI
import SkipRevenueCat
import OSLog

struct StoreViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
        .task {
            logger.info("Start fetching offerings")
            
            #if !os(macOS) || SKIP
            Purchases.sharedInstance.getOfferings(onError: { error in
                logger.error("Error fetching offerings: \(error)")
            }, onSuccess: { offerings in
                Store.shared.offerings = offerings
            })
            #endif
        }
    }
}

