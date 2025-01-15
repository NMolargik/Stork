//
//  CustomPaywallContent.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import SkipRevenueCat

#if !SKIP
import RevenueCatUI
#else
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallFooter
import com.revenuecat.purchases.ui.debugview.DebugRevenueCatScreen
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallOptions
#endif

public struct PaywallView: View {
    @ObservedObject var storeViewModel = Store.shared
    
    public init() {
    }

    public var body: some View {
        #if SKIP
        let options = remember {
            PaywallOptions(dismissRequest: {}) { }
        }
        #endif

        #if !SKIP && os(iOS)
        CustomPaywall()
            .paywallFooter()
        #elseif SKIP
        ComposeView { context in
            PaywallFooter(options) { _ in
                CustomPaywall()
                    .Compose(context: context.content())
            }
        }
        #endif
    }
}
