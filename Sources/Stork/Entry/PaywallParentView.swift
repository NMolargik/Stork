//
//  PaywallParentView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/21/25.
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

struct PaywallParentView: View {
    @ObservedObject var storeViewModel = Store.shared
        
    @Binding var isPresented: Bool
    @State private var isCustomPaywallPresented = false
    @State private var debugOverlayVisible: Bool = false
    @State private var subscriptionActive: Bool = false

    public var body: some View {
        #if SKIP
        let options = remember {
            PaywallOptions(dismissRequest: {}) { }
        }
        #endif

        VStack {
            if (subscriptionActive) {
                Text("You're subscribed!")
            } else {
            #if !SKIP && os(iOS)
            CustomPaywallContent()
                .paywallFooter(
                    condensed: false,
                    purchaseStarted: { package in
                        print("Purchases: Purchase Started")
                        //TODO: manage

                    }, purchaseCompleted: { completedHandler in
                        print("Purcahses: Purchase Completed")
                        print("Purchases: New Entitlements: \(completedHandler.entitlements.active)")
                        isPresented = false
                    }, purchaseCancelled: {
                        print("Purcahses: Purchase Cancelled")
                        //TODO: manage
                    }, restoreStarted: {
                        print("Purcahses: Restore Started")
                        //TODO: manage

                    }, restoreCompleted: { completedHandler in
                        print("Purcahses: Restore Completed")
                        print("Purchases: Restored Entitlements: \(completedHandler.entitlements.active)")
                        //TODO: manage

                    }, purchaseFailure: { failureHandler in
                        print("Purchases: Purchase Failure")
                        //TODO: manage

                    }, restoreFailure: { restoreHandler in
                        print("Purchases: Restore Failed")
                        //TODO: manage

                    }
                )
            #elseif SKIP
            ComposeView { context in
                PaywallFooter(options) { _ in
                    CustomPaywallContent()
                        .Compose(context: context.content())
                }
            }
            #endif
            }
        }
        .onAppear {
            subscriptionActive = Store.shared.subscriptionActive
        }
    }
}

#Preview {
    PaywallParentView(isPresented: .constant(false))
}
