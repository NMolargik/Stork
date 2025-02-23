//
//  PaywallMarketingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/21/25.
//

import SwiftUI

struct PaywallMarketingView: View {
    let signOut: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        ZStack {
                            Image("storkicon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: min(geometry.size.width * 0.6, 250)) // Adaptive size
                                .background {
                                    Circle()
                                        .foregroundStyle(.black)
                                }
                            
                            Text("Stork Annual")
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
                                .offset(y: min(geometry.size.width * 0.2, 125)) // Scales offset
                        }
                        
                        Text("Spread Your Wings!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                        #if !SKIP
                            .minimumScaleFactor(0.8) // Allows shrinking for small screens
                        #endif
                        
                        featureSection(
                            icon: "storkBlue",
                            title: "Track Your Deliveries!",
                            description: "See your deliveries at a glance with your jar, or dive deeper into statistics or details from a particular delivery."
                        )
                        
                        featureSection(
                            icon: "person.3.fill",
                            title: "Muster Up!",
                            description: "Group up with your coworkers to contribute to a larger set of delivery trend data."
                        )
                    }
                    .frame(maxWidth: .infinity) // Expands content properly
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
    
    @ViewBuilder
    private func featureSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .offset(y: 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                #if !SKIP
                    .minimumScaleFactor(0.8) // Shrinks if needed
                #endif
                
                Text(description)
                    .font(.system(size: 16))
                #if !SKIP
                    .minimumScaleFactor(0.8)
                #endif
                
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    PaywallMarketingView(signOut: {})
}
