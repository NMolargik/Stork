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
    @EnvironmentObject var appStateManager: AppStateManager
    
    @Binding var deliveries: [Delivery]
    var startNewDelivery: @MainActor () -> Void
    
    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            ZStack {
                JarView(
                    deliveries:
                        Binding(get: { deliveries },
                                set: { deliveries = $0 ?? [] }
                        ),
                    isMuster: false,
                    headerText: currentMonth,
                    isTestMode: false
                )
            }

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
