//
//  HomeBodyView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

@MainActor
struct HomeBodyView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStateManager: AppStateManager
    
    @Binding var deliveries: [Delivery]
    var startNewDelivery: @MainActor () -> Void

    var body: some View {
        HStack {
            ZStack {
                JarView(
                    deliveries:
                        Binding(get: { deliveries },
                                set: { deliveries = $0 ?? [] }
                        ),
                    headerText: appStateManager.currentWeekRange,
                    isTestMode: false,
                    isMusterTest: false
                )
                
                VStack {
                    if !appStateManager.currentWeekRange.isEmpty {
                        Text(appStateManager.currentWeekRange)
                            .padding(8)
                            .foregroundStyle(.gray)
                            .font(.headline)
                            .fontWeight(.bold)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(20)
                                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                            }
                            .padding(.top, 20)
                    }
                    Spacer()
                }
            }
            
            Spacer()
            
            VStack {
                JarSummaryView(deliveries: $deliveries)
                
                Spacer()
                    
                Button(action: {
                    Task {
                        HapticFeedback.trigger(style: .medium)
                        withAnimation {
                            appStateManager.showingDeliveryAddition = true
                            appStateManager.selectedTab = Tab.deliveries
                            startNewDelivery()
                        }
                        
                    }
                }, label: {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(Color("storkIndigo"))
                            .cornerRadius(15)
                            .shadow(radius: 2)
                        
                        Image("plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 35 )
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                })
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .padding(.horizontal, 5)
            }
            .padding(.leading, 8)
        }
        .frame(height: 300)
    }
}

#Preview {
    HomeBodyView(deliveries: .constant([]), startNewDelivery: { })
        .environmentObject(AppStateManager.shared)
}
