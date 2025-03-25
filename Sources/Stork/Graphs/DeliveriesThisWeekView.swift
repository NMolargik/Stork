//
//  DeliveriesThisWeekView.swift
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

// MARK: - DeliveriesThisWeek View
struct DeliveriesThisWeekView: View {
    // MARK: - Properties
    @Binding var deliveries: [Delivery]
    
    /// Aggregated deliveries for the last seven days
    @State private var deliveriesLastSevenDays: [DeliveryGraphData] = []
    @State private var animatedDeliveries: [DeliveryGraphData] = []
    
    /// Date Formatter for X-Axis Labels
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        VStack {
            if deliveriesLastSevenDays.isEmpty {
                Text("No delivery data available for the past seven days.")
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Deliveries This Week")
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                    .offset(y: 25)
                    .frame(height: 10)
                    .padding(.bottom, 10)
                
                // MARK: - Line Chart
                Chart(animatedDeliveries) { dailyDelivery in
                    AreaMark(
                        x: .value("Day", dailyDelivery.date, unit: .day),
                        y: .value("Deliveries", dailyDelivery.count)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(LinearGradient(colors: [Color("storkIndigo"), .clear], startPoint: .top, endPoint: .bottom))
                    
                    LineMark(
                        x: .value("Day", dailyDelivery.date, unit: .day),
                        y: .value("Deliveries", dailyDelivery.count)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color("storkIndigo"))
                    
                    PointMark(
                        x: .value("Day", dailyDelivery.date, unit: .day),
                        y: .value("Deliveries", dailyDelivery.count)
                    )
                    .foregroundStyle(Color("storkOrange"))
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text("\(dailyDelivery.count)")
                            .fontWeight(.bold)
                            .font(.caption)
                            .foregroundStyle(.primary)
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
        .onAppear {
            aggregateDeliveries()
        }
        .onChange(of: deliveries) { _ in
            aggregateDeliveries()
        }
    }
    
    private func aggregateDeliveries() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // Determine the start of the week (most recent Sunday)
        let daysSinceSunday = weekday - 1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysSinceSunday, to: today) else {
            deliveriesLastSevenDays = []
            return
        }
        
        // Compute the upcoming Saturday (6 days after Sunday) and get its end-of-day
        guard let saturday = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            deliveriesLastSevenDays = []
            return
        }
        let saturdayStart = calendar.startOfDay(for: saturday)
        // Instead of using date(bySettingHour:minute:second:of:), we get the start of Sunday (day after Saturday) and subtract one second
        guard let startOfNextSunday = calendar.date(byAdding: .day, value: 1, to: saturdayStart) else {
            deliveriesLastSevenDays = []
            return
        }
        let endOfWeek = startOfNextSunday.addingTimeInterval(-1)
        
        // Build a dictionary for each day in the week (Sunday through Saturday) with an initial count of 0.
        var counts: [Date: Int] = [:]
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) {
                counts[date] = 0
            }
        }
        
        // Iterate through deliveries and count those within the week range.
        for delivery in deliveries {
            let deliveryDate = calendar.startOfDay(for: delivery.date)
            if deliveryDate >= startOfWeek && deliveryDate <= endOfWeek {
                counts[deliveryDate, default: 0] += 1
            }
        }
        
        // Convert the dictionary into a sorted array of DeliveryGraphData.
        let updatedData = counts.map { DeliveryGraphData(date: $0.key, count: $0.value) }
                                 .sorted { $0.date < $1.date }
        
        // Animate the update.
        withAnimation(.easeInOut(duration: 1.0)) {
            deliveriesLastSevenDays = updatedData
            animatedDeliveries = updatedData
        }
    }
}

// MARK: - Preview
struct DeliveriesThisWeekView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveriesThisWeekView(deliveries: .constant([]))
            .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
    }
}

#endif
