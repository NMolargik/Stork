//
//  PaywallMainView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/21/25.
//

import SwiftUI
import SkipRevenueCat

#if SKIP
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallFooter
import com.revenuecat.purchases.ui.debugview.DebugRevenueCatScreen
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallOptions
#else
import RevenueCatUI
#endif

struct PaywallMainView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    @ObservedObject var storeViewModel = Store.shared

    let onCompleted: () -> Void  // Callback for closing the paywall
    let signOut: () -> Void       // Callback for signing out

    public var body: some View {
        #if SKIP
        let options = rememberStorkPaywallOptions(
            onCompleted: { onCompleted() },
            setError: { message in withAnimation { appStateManager.errorMessage = message } }
        )
        
        ZStack {
            PaywallMarketingView(signOut: signOut)
                .modifier(StoreViewModifier())
            
            VStack(spacing: 0) {
                ComposeView { context in
                    PaywallFooter(options) { _ in
                        // Android footer; marketing header already rendered above
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.footnote)
                        .foregroundStyle(Color("storkBlue"))
                    
                    Spacer()
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.nickmolargik.tech/stork-privacy-policy")!)
                        .font(.footnote)
                        .foregroundStyle(Color("storkBlue"))
                    
                    Spacer()
                }
                .background {
                    Color.white
                        .ignoresSafeArea()
                    
                }
            }
        }
        #else
        
        VStack(spacing: 0) {
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
                        withAnimation {
                            appStateManager.errorMessage = "Purchase Cancelled"
                        }
                    }, restoreStarted: {
                        print("Purchases: Restore Started")
                        withAnimation {
                            appStateManager.errorMessage = "Searching for existing subscription..."
                        }
                    }, restoreCompleted: { completedHandler in
                        print("Purchases: Restore Completed")
                        print("Purchases: Restored Entitlements: \(completedHandler.entitlements.active)")
                        onCompleted()
                    }, purchaseFailure: { failureHandler in
                        print("Purchases: Purchase Failure")
                        withAnimation {
                            appStateManager.errorMessage = "Purchase failed. Please try again"
                        }
                    }, restoreFailure: { restoreHandler in
                        print("Purchases: Restore Failed")
                        withAnimation {
                            appStateManager.errorMessage = "No existing subscription found"
                        }
                    }
                )
            
            HStack {
                Spacer()
                
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.footnote)
                    .foregroundStyle(Color("storkBlue"))
                
                Spacer()
                
                Link("Privacy Policy", destination: URL(string: "https://www.nickmolargik.tech/stork-privacy-policy")!)
                    .font(.footnote)
                    .foregroundStyle(Color("storkBlue"))
                
                Spacer()
            }
            .background {
                Color.white
                    .ignoresSafeArea()

            }
        }
        #endif
    }
}

#Preview {
    PaywallMainView(
        onCompleted: {},
        signOut: {}
    )
    .environmentObject(AppStateManager.shared)
}
