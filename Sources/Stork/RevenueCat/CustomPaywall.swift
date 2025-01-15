//
//  CustomPaywall.swift
//  skip-revenuecat-app
//
//  Created by Alexey Duryagin on 15/01/2025.
//

import SwiftUI
import SkipRevenueCat

struct CustomPaywall: View {
    @State private var isPurchasing = false
    @State private var error: String?
    @State private var displayError: Bool = false
    
    @Binding private var isPresented: Bool
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        let package = Store.shared.offerings?.current?.getPackage(identifier: StoreConstants.packageID)
        
        Button {
            Task {
                isPurchasing = true

                Purchases.sharedInstance.purchase(
                    packageToPurchase: package!,
                    onError: { error, userCancelled in
                        // No purchase
                        
                        self.error = error.underlyingErrorMessage ?? error.message
                        self.displayError = true
                        
                        isPurchasing = false
                    },
                    onSuccess: { storeTransaction, customerInfo in
                        let entitlement = customerInfo.entitlements.get(s: StoreConstants.entitlementID)
                        Store.shared.subscriptionActive = entitlement?.isActive == true

                        isPurchasing = false
                    },
                    isPersonalizedPrice: false,
                    // If [storeProduct] represents a non-subscription, [oldProductId] and [replacementMode] will be ignored.
                    oldProductId: nil,
                    replacementMode: nil
                )
            }
        } label: {
            let offerings = Store.shared.offerings
            
            if (offerings == nil) {
                ProgressView()
            } else {
                HStack {
                    VStack {
                        HStack {
                            Text(package?.storeProduct.title ?? "")
                                .font(.title3)
                                .bold()
                            
                            if (isPurchasing) { ProgressView() }

                            Spacer()
                        }
                    }
                    .padding([.top, .bottom], 8.0)

                    Spacer()

                    Text(package?.storeProduct.price.formatted ?? "")
                        .font(.title3)
                        .bold()
                }
                #if os(iOS)
                .contentShape(Rectangle())
                #endif
            }
        }
        // SKIP NOWARN
        .alert(self.error ?? "", isPresented: $displayError) {
            Button("OK") {
                displayError = false
            }
        }
#if os(iOS)
        .buttonStyle(.plain)
        #endif
    }
    
}
