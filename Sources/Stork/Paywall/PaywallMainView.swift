//
//  PaywallMainView.swift
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

struct PaywallMainView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    @ObservedObject var storeViewModel = Store.shared

    let onCompleted: () -> Void  // Callback for closing the paywall
    let signOut: () -> Void       // Callback for signing out

    public var body: some View {
        #if SKIP
        let options = remember {
            PaywallOptions(dismissRequest: {}) { }
        }
        #endif

        ZStack {
            VStack {
#if !SKIP && os(iOS)
                PaywallMarketingView(signOut: signOut)
                    .modifier(StoreViewModifier())
                    .paywallFooter(
                        condensed: false,
                        purchaseStarted: { package in
                            print("Purchases: Purchase Started")
                            
                        }, purchaseCompleted: { completedHandler in
                            print("Purchases: Purchase Completed")
                            print("Purchases: New Entitlements: \(completedHandler.entitlements.active)")
                            onCompleted()
                            
                        }, purchaseCancelled: {
                            print("Purchases: Purchase Cancelled")
                            errorMessage = "Purchase Cancelled"
                            
                        }, restoreStarted: {
                            print("Purchases: Restore Started")
                            errorMessage = "Searching for existing subscription..."
                            
                        }, restoreCompleted: { completedHandler in
                            print("Purchases: Restore Completed")
                            print("Purchases: Restored Entitlements: \(completedHandler.entitlements.active)")
                            onCompleted()
                            
                        }, purchaseFailure: { failureHandler in
                            print("Purchases: Purchase Failure")
                            errorMessage = "Purchase failed. Please try again"
                            
                        }, restoreFailure: { restoreHandler in
                            print("Purchases: Restore Failed")
                            errorMessage = "No existing subscription found"
                        }
                    )
#elseif SKIP
                //TODO: Android: fix paywall results
                ComposeView { context in
                    PaywallFooter(options) { _ in
                        PaywallMarketingView(signOut: {})
                            .Compose(context: context.content())
                    }
                }
#endif
                
                HStack {
                    Spacer()
                    
                    Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.footnote)
                        .foregroundColor(Color("storkBlue"))
                    
                    Spacer()
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.nickmolargik.tech/stork-privacy-policy")!)
                        .font(.footnote)
                        .foregroundColor(Color("storkBlue"))
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PaywallMainView(
        onCompleted: {},
        signOut: {}
    )
}
