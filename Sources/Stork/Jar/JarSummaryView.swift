//
//  JarSummaryView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/11/25.
//

import SwiftUI
import StorkModel

struct JarSummaryView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @State private var babyCounts: [Sex: Int] = [:]

    @Binding var deliveries: [Delivery]

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("This Month")
                .foregroundStyle(.gray)

            Divider()
                .padding(.horizontal)

            HStack {
                Text("\(babyCounts[.male, default: 0])")
                    .foregroundStyle(Color("storkBlue"))
                    .lineLimit(1)
                    .font(.title3)
                    .bold()
                    .shadow(radius: 2)
                    .frame(width: 40)

                ScalableText(text: "Boy\(babyCounts[.male, default: 0] == 1 ? "" : "s")", minWidth: 100)
                    .foregroundStyle(.gray )

            }

            HStack {
                Text("\(babyCounts[.female, default: 0])")
                    .foregroundStyle(Color("storkPink"))
                    .lineLimit(1)
                    .font(.title3)
                    .bold()
                    .shadow(radius: 2)
                    .frame(width: 40)

                ScalableText(text: "Girl\(babyCounts[.female, default: 0] == 1 ? "" : "s")", minWidth: 100)
                    .foregroundStyle(.gray)

            }

            HStack {
                Text("\(babyCounts[.loss, default: 0])")
                    .foregroundStyle(Color("storkPurple"))
                    .lineLimit(1)
                    .font(.title3)
                    .bold()
                    .shadow(radius: 2)
                    .frame(width: 40)

                ScalableText(text: "Loss\(babyCounts[.loss, default: 0] == 1 ? "" : "es")", minWidth: 100)
                    .foregroundStyle(.gray)

            }

        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .font(.title2)
        .fontWeight(.bold)
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
        .onAppear { updateCount() }
        .onChange(of: deliveries) { _ in updateCount() }
        .onReceive(timer) { _ in updateCount() }
    }
    
    private func updateCount() {
        babyCounts = Dictionary(uniqueKeysWithValues: Sex.allCases.map { ($0, countBabies(of: $0)) })
    }
    
    private func countBabies(of sex: Sex) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        
        // Get the end of the current month by adding 1 month and subtracting 1 second
        var components = DateComponents()
        components.month = 1
        components.second = -1
        guard let endOfMonth = calendar.date(byAdding: components, to: startOfMonth) else {
            return 0
        }
        
        // Filter deliveries that occurred within the current month (from startOfMonth to endOfMonth)
        let monthDeliveries = deliveries.filter { delivery in
            return delivery.date >= startOfMonth && delivery.date <= endOfMonth
        }
        
        // Count the babies with the matching sex from the filtered deliveries
        return monthDeliveries.reduce(0) { count, delivery in
            count + delivery.babies.filter { $0.sex == sex }.count
        }
    }
}

#Preview {
    JarSummaryView(deliveries: .constant([]))
}
