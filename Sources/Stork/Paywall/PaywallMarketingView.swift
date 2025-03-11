//
//  PaywallMarketingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/21/25.
//

import SwiftUI

struct PaywallMarketingView: View {
    @Environment(\.colorScheme) var colorScheme

    let signOut: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 5) {
                        ZStack {
                            Image("storkicon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: min(geometry.size.width * 0.6, 250)) // Adaptive size
                                .background {
                                    Circle()
                                        .foregroundStyle(.black)
                                }
                            
                            Text("Stork Monthly")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .shadow(radius: 2)
                                        .foregroundStyle(Color("storkOrange"))
                                }
                                .offset(y: min(geometry.size.width * 0.2, 125))
                        }
                        
                        Text("Spread Your Wings!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                        #if !SKIP
                            .minimumScaleFactor(0.8)
                        #endif
                        
                        HStack {
                            VStack {
                                Image("shippingbox.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color("storkBlue"))
                                    .frame(width: 24, height: 24)
                                    .padding()
                                    .padding(.bottom)
                                
                                Image("person.3.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color("storkPurple"))
                                    .frame(width: 24, height: 24)
                                    .padding()
                            }
                            
                            VStack (alignment: .leading){
                                Text("Track Your Deliveries!")
                                    .font(.system(size: 18, weight: .semibold))
                                #if !SKIP
                                    .minimumScaleFactor(0.8)
                                #endif
                                
                                Text("See your deliveries at a glance with your jar, or dive deeper into statistics or details from a particular delivery.")
                                    .font(.system(size: 16))
                                #if !SKIP
                                    .minimumScaleFactor(0.8)
                                #endif
                                    .padding(.bottom)
                                
                                Text("Muster Up!")
                                    .font(.system(size: 18, weight: .semibold))
                                #if !SKIP
                                    .minimumScaleFactor(0.8)
                                #endif
                                
                                Text("Group up with your coworkers to contribute to a larger set of delivery trend data.")
                                    .font(.system(size: 16))
                                #if !SKIP
                                    .minimumScaleFactor(0.8)
                                #endif
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            triggerHaptic()
                            signOut()
                        }) {
                            Text("Sign Out")
                                .foregroundColor(Color("storkOrange"))
                                .font(.footnote)
                                .fontWeight(.bold)
                                .padding()
                        }
                    }
                    .padding(5)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PaywallMarketingView(signOut: {})
}
