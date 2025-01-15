//
//  CustomPaywall.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/15/25.
//

import Foundation
import SwiftUI

struct CustomPaywall: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
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
                
                VStack {
                    Spacer()
                    
                    Text("1 Year")
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
            
            Text("Purchase a year's worth of Stork to access our labor and delivery statistic services!\n\nYour contribution directly enables us to keep Stork's services alive and kicking.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            CustomButtonView(text: "Sign Out", width: 120, height: 50, color: Color.orange, isEnabled: true, onTapAction: {
                profileViewModel.signOut()
            })
            
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
