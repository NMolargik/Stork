//
//  JarSummaryView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/11/25.
//

import SwiftUI
import StorkModel

struct JarSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var deliveries: [Delivery]

    @State private var babyCounts: [Sex: Int] = [:]
    
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("Your Jar")
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
        .backgroundCard(colorScheme: colorScheme)
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
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // Calculate the most recent Sunday
        let daysSinceSunday = weekday - 1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysSinceSunday, to: today) else {
            return 0
        }
        
        // Calculate the upcoming Saturday
        guard let saturday = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return 0
        }
        let saturdayStart = calendar.startOfDay(for: saturday)
        // Get the start of the next Sunday and subtract one second to get the end-of-Saturday
        guard let startOfNextSunday = calendar.date(byAdding: .day, value: 1, to: saturdayStart) else {
            return 0
        }
        let endOfWeek = startOfNextSunday.addingTimeInterval(-1)
        
        // Filter deliveries that occurred within the full week (Sunday 00:00:00 to Saturday 23:59:59)
        let weekDeliveries = deliveries.filter { delivery in
            return delivery.date >= startOfWeek && delivery.date <= endOfWeek
        }
        
        // Count the babies with the matching sex from the filtered deliveries
        return weekDeliveries.reduce(0) { count, delivery in
            count + delivery.babies.filter { $0.sex == sex }.count
        }
    }
}

#Preview {
    JarSummaryView(deliveries: .constant([]))
}
