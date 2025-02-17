//
//  PaywallMarketingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/21/25.
//

import Foundation
import SwiftUI

struct PaywallMarketingView: View {
    let signOut: () -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                ZStack {
                    Image("storkicon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250)
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
                            Rectangle()
                                .cornerRadius(20)
                                .shadow(radius: 2)
                                .foregroundStyle(Color("storkOrange"))
                            
                        }
                        .offset(y: 125)
                }
                
                Text("Spread Your Wings!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 30)
                    .padding(.top, 30)
                
                HStack(alignment: .top) {
                    SampleMarbleView(color: Color("storkBlue"))
                        .frame(width: 30)
                        .offset(y: 2)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Track Your Deliveries!")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("See your deliveries at a glance with your jar, or dive deeper into statistics or details from a particular delivery.")
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal)
                
                HStack(alignment: .top) {
                    Image("person.3.fill")
                        .resizable()
                        .scaledToFit()
                        .shadow(radius: 2)
                        .frame(width: 30)
                        .foregroundStyle(Color("storkIndigo"))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Muster Up!")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Group up with your coworkers to contribute to a larger set of delivery trend data.")
                            .font(.system(size: 16))
                    }
                }
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
    
    @ViewBuilder
    private func feature(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        warning: LocalizedStringKey? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .offset(y: 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    PaywallMarketingView(signOut: {})
}
