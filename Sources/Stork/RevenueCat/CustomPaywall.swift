//
//  CustomPaywall.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/15/25.
//

import Foundation
import SwiftUI
import SkipRevenueCat

struct CustomPaywall: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var isPurchasing = false
    @State private var error: String?
    @State private var displayError: Bool = false
    
    @Binding private var isPresented: Bool
    
    let package = Store.shared.offerings?.current?.getPackage(identifier: StoreConstants.packageID)
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        self.content
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                Image("storkicon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
                    .background {
                        Circle()
                            .foregroundStyle(Color.indigo)
                    }
                    .padding(2)
                    .background {
                        Circle()
                            .foregroundStyle(Color.orange)
                    }
                
                VStack {
                    Spacer()
                    
                    Text("Stork Annual")
                        .font(.title3)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .fontWeight(.bold)
                        .background {
                            Rectangle()
                                .cornerRadius(5)
                                .foregroundStyle(.yellow)
                                .shadow(radius: 2)
                        }
                }
            }
            .frame(height: 290)
            
            Text("Spread Your Wings!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Purchase a year's worth of Stork to access our labor and delivery statistic services!\n\nYour contribution directly enables us to keep Stork's services in the air.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Button {
                Task {
                    isPurchasing = true

                    Purchases.sharedInstance.purchase(
                        packageToPurchase: self.package!,
                        onError: { error, userCancelled in
                            // No purchase
                            
                            self.error = error.underlyingErrorMessage ?? error.message
                            self.displayError = true
                            
                            isPurchasing = false
                        },
                        onSuccess: { storeTransaction, customerInfo in
                            let entitlement = customerInfo.entitlements.get(s: StoreConstants.entitlementID)
                            Store.shared.subscriptionActive = entitlement?.isActive == true
                            print("/n/n/n PURCHASE SUCCESSFUL")
                            isPurchasing = false
                            self.isPresented = false
                        },
                        isPersonalizedPrice: false,
                        // If [storeProduct] represents a non-subscription, [oldProductId] and [replacementMode] will be ignored.
                        oldProductId: nil,
                        replacementMode: nil
                    )
                    
                    print("PURCHASE COMPLETE, NO UPDATE")
                }
            } label: {
                let offerings = Store.shared.offerings

                HStack {
                    VStack {
                        HStack {
                            Text(self.package?.storeProduct.title ?? "")
                                .font(.title3)
                                .bold()
                            
                            if (isPurchasing) { ProgressView() }

                            Spacer()
                        }
                    }
                    .padding([.top, .bottom], 8.0)

                    Spacer()

                    Text(self.package?.storeProduct.price.formatted ?? "")
                        .font(.title3)
                        .bold()
                }
                #if os(iOS)
                .contentShape(Rectangle())
                #endif
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
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func feature(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        warning: LocalizedStringKey? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: 18
                    )
                )
                .frame(width: 30)
                .offset(y: 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Text(description)
                    .font(.system(size: 16))
            }
        }.padding(.horizontal)
    }
}
