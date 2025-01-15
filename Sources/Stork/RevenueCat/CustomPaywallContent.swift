//
//  CustomPaywallContent.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import Foundation
import SkipRevenueCat

struct PaywallView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @AppStorage("errorMessage") private var errorMessage: String = ""
    @AppStorage("selectedTab") var selectedTab = Tab.home
    @AppStorage("isPaywallComplete") private var isPaywallComplete: Bool = false

    // MARK: Environment Variables
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @ObservedObject var storeViewModel = Store.shared
    var handler = PurchasesDelegateHandler.shared
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Circle()
                        .foregroundStyle(.white)
                        .frame(width: 2000)
                        .offset(y: -115)
                        .ignoresSafeArea()
                    
                    Image("storkicon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350)
                        .offset(y: -80)

                }

                Group {
                    Text("\(profileViewModel.profile.firstName),\nSpread Your Wings Today!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .frame(width: 400)
                        .padding(.bottom)
                    
                    // Description
                    Text("Get access to Stork's labor and delivery statistics tracking features, muster grouping, and your marble jar for one annual payment. Cancel anytime!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(width: 400)
                        .padding(.bottom, 10)
                }
                .offset(y: -80)

                Spacer()
                
                // Price
                Text("Annual access for just $4.99/yr")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 300)
                
                Text("Plus, a 1 week free trial!")
                    .foregroundColor(.white)
                    .frame(width: 300)


                
                CustomButtonView(text: "Sign Me Up!", width: 350, height: 60, color: Color.orange, isEnabled: true) {
                    triggerHaptic()
                    print("Sign Me Up button tapped!")

//                    guard let promoProduct = storeViewModel.offerings?.all.first else {
//                        print("No promo product available!")
//                        return
//                    }
                    
                    // TODO: fix this
                    self.isPaywallComplete = true
                    self.appState = .main
                    
                    
//                    Purchases.sharedInstance.purchase(promoProduct) { transaction, customerInfo, error, userCancelled in
//                        if let error = error {
//                            // 2) Pass the error/cancellation back
//                            print("purchase error")
//                            return
//                        }
//
//                        // 3) If purchase was successful, pass success
//                        if let transaction = transaction, let customerInfo = customerInfo {
//                            print("purchase success")
//                        }
//                    }
                }
                    
                .padding(.bottom)
                
                // Restore Button
                Button(action: {
                    triggerHaptic()
                    print("Restore button tapped!")
                }) {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
            }
            .background {
                Color.indigo
                    .ignoresSafeArea()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
}


#Preview {
    PaywallView()
}
