//
//  YourJarView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/11/25.
//

import SwiftUI
import StorkModel

struct YourJarView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var deliveries: [Delivery]
    
    @State private var maleCount = 0
    @State private var femaleCount = 0
    @State private var lossCount = 0
    
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Your Jar")
            
            Divider()
                .padding(.horizontal)

            HStack {
                Text("\(maleCount)")
                
                Text("Boy\(maleCount == 1 ? "" : "s")")
                    .frame(width: 100)
            }
            
            HStack {
                Text("\(femaleCount)")
                
                Text("Girl\(femaleCount == 1 ? "" : "s")")
                    .frame(width: 100)
            }
            
            HStack {
                Text("\(lossCount)")
                
                Text("Loss\(lossCount == 1 ? "" : "es")")
                    .frame(width: 100)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(.gray)
        .background {
            Rectangle()
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .cornerRadius(20)
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
        }
        .onAppear {
            updateCount()
        }
        .onChange(of: deliveries) { _ in
            updateCount()
        }
        .onReceive(timer) { _ in
            updateCount()
        }
    }
    
    private func updateCount() {
        self.maleCount = countBabies(of: .male)
        self.femaleCount = countBabies(of: .female)
        self.lossCount = countBabies(of: .loss)
        
        print(maleCount)
        print(femaleCount)
        print(lossCount)
    }
    
    private func countBabies(of sex: Sex) -> Int {
        let calendar = Calendar.current
        let now = Date()

        // Define the start as “7 days (6 full days) before now”
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: now) else {
            return 0
        }

        // Filter deliveries for the last 7 days (from sevenDaysAgo up to now)
        let last7DaysDeliveries = deliveries.filter { delivery in
            delivery.date >= sevenDaysAgo && delivery.date <= now
        }

        // Count babies of the specified sex
        return last7DaysDeliveries.reduce(0) { count, delivery in
            count + delivery.babies.filter { $0.sex == sex }.count
        }
    }
}


