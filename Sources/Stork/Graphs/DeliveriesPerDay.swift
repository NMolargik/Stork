//
//  DeliveriesPerDay.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

#if !SKIP
import SwiftUI
import StorkModel
import Charts

// MARK: - DeliveryData Model
struct DeliveryGraphData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - DeliveriesPerDay View
struct DeliveriesPerDay: View {
    // MARK: - Properties
    @Binding var deliveries: [Delivery]
    
    /// Aggregated deliveries for the last seven days
    @State private var deliveriesLastSevenDays: [DeliveryGraphData] = []
    
    /// Date Formatter for X-Axis Labels
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // e.g., Mon, Tue
        return formatter
    }()
    
    var body: some View {
        VStack {
            if deliveriesLastSevenDays.isEmpty {
                Text("No delivery data available for the past seven days.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("No delivery data available for the past seven days.")
            } else {
                
                Text("Deliveries Per Day")
                    .fontWeight(.bold)
                
                // MARK: - Line Chart
                Chart(deliveriesLastSevenDays) { dailyDelivery in
                    LineMark(
                        x: .value("Day", dailyDelivery.date, unit: .day),
                        y: .value("Deliveries", dailyDelivery.count)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color.orange)
                    
                    PointMark(
                        x: .value("Day", dailyDelivery.date, unit: .day),
                        y: .value("Deliveries", dailyDelivery.count)
                    )
                    .foregroundStyle(Color.indigo)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text("\(dailyDelivery.count)")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .accessibilityLabel("\(dailyDelivery.count) deliveries")
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { date in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.short))
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(width: 300, height: 175)

        .onAppear {
            aggregateDeliveries()
        }
        .onChange(of: deliveries) { _ in
            aggregateDeliveries()
        }
    }
    // MARK: - Data Aggregation
    
    /// Aggregates the number of deliveries per day for the last seven days.
    private func aggregateDeliveries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            deliveriesLastSevenDays = []
            return
        }
        
        // Initialize a dictionary to hold counts per day
        var counts: [Date: Int] = [:]
        
        // Initialize counts to zero for each day in the range
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: sevenDaysAgo) {
                counts[date] = 0
            }
        }
        
        // Iterate through deliveries and count those within the last seven days
        for delivery in deliveries {
            let deliveryDate = calendar.startOfDay(for: delivery.date)
            if deliveryDate >= sevenDaysAgo && deliveryDate <= today {
                counts[deliveryDate, default: 0] += 1
            }
        }
        
        // Convert the dictionary to an array of DeliveryData, sorted by date
        deliveriesLastSevenDays = counts.map { DeliveryGraphData(date: $0.key, count: $0.value) }
                                         .sorted { $0.date < $1.date }
    }
}

// MARK: - Preview
struct DeliveriesPerDay_Previews: PreviewProvider {
    static var previews: some View {
        DeliveriesPerDay(deliveries: .constant([]))
            .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
    }
}

#endif
