//
//  HomeTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI

struct HomeTabView: View {
    @Binding var navigationPath: [String]
    @Binding var selectedTab: Tab
    @Binding var showingDeliveryAddition: Bool
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                Spacer()
                
                Button(action: {
                    
                }, label: {
                    CustomButtonView(text: "Start A New Delivery", width: 250, height: 50, color: Color.indigo, isEnabled: .constant(true), onTapAction: {
                        withAnimation {
                            showingDeliveryAddition = true
                            selectedTab = .deliveries
                        }
                    })
                })
            }
            .navigationTitle("Stork")
            .navigationDestination(for: String.self) { value in
                if value == "ProfileView" {
                    Text("Shared Profile View")
                } else {
                    Text("Other View: \(value)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            navigationPath.append("ProfileView")
                        }
                    }, label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    })
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeTabView(navigationPath: .constant([]), selectedTab: .constant(Tab.home), showingDeliveryAddition: .constant(false))
}
