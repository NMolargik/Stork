//
//  DeliveriesLastSixMonthsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

#if !SKIP
import SwiftUI
import Charts
import StorkModel

// MARK: - DeliveryGraphMonthData Model
/// Represents the aggregated delivery data for a specific month.
struct DeliveryGraphMonthData: Identifiable {
    let id = UUID()
    let month: String      // e.g., "December '24"
    let date: Date         // First day of the month for accurate plotting
    let count: Int         // Number of deliveries in the month
}

// MARK: - DeliveriesLastSixMonthsView View
/// A SwiftUI view that displays a line chart of deliveries per month for the last six months.
struct DeliveriesLastSixMonthsView: View {
    // MARK: - Properties
    
    @Binding var groupedDeliveries: [GroupedDeliveries]
    @State private var deliveriesLastSix: [DeliveryGraphMonthData] = []
    @State private var animatedDeliveries: [DeliveryGraphMonthData] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM ''yy"
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: - Body
    var body: some View {
        VStack {
            Text("Deliveries In The Last 6 Months")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .offset(y: 25)
                .frame(height: 10)
                .padding(.bottom, 10)
            
            // MARK: - Line Chart
            Chart(animatedDeliveries) { monthlyData in
                AreaMark(
                    x: .value("Month", monthlyData.date, unit: .month),
                    y: .value("Deliveries", monthlyData.count)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("storkIndigo"), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Month", monthlyData.date, unit: .month),
                    y: .value("Deliveries", monthlyData.count)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(Color("storkIndigo"))
                
                PointMark(
                    x: .value("Month", monthlyData.date, unit: .month),
                    y: .value("Deliveries", monthlyData.count)
                )
                .foregroundStyle(Color("storkOrange"))
                .symbolSize(100)
                .annotation(position: .top) {
                    Text("\(monthlyData.count)")
                        .fontWeight(.bold)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 1)) { date in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .padding()
        }
        .onAppear {
            aggregateMonthlyDeliveries()
        }
        .onChange(of: groupedDeliveries.count) { _ in
            aggregateMonthlyDeliveries()
        }
    }
    
    // MARK: - Data Aggregation
    private func aggregateMonthlyDeliveries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var lastSixMonthsKeys: [String] = []
        var lastSixMonthsDates: [Date] = []
        
        for offset in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -offset, to: today) {
                let key = dateFormatter.string(from: date)
                lastSixMonthsKeys.append(key)
                
                let components = calendar.dateComponents([.year, .month], from: date)
                if let firstOfMonth = calendar.date(from: components) {
                    lastSixMonthsDates.append(firstOfMonth)
                }
            }
        }
        
        lastSixMonthsKeys.reverse()
        lastSixMonthsDates.reverse()
        
        var tempAggregatedData: [DeliveryGraphMonthData] = []
        
        for (index, key) in lastSixMonthsKeys.enumerated() {
            if let deliveriesInMonth = groupedDeliveries.first(where: { $0.key == key })?.deliveries {                let count = deliveriesInMonth.count
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: count)
                tempAggregatedData.append(monthData)
            } else {
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: 0)
                tempAggregatedData.append(monthData)
            }
        }
        
        // Assign to the state variable.
        self.deliveriesLastSix = tempAggregatedData
        
        // Animate the data
        withAnimation(.easeInOut(duration: 1.5)) {
            self.animatedDeliveries = tempAggregatedData
        }
    }
}

#endif

#Preview {
    DeliveriesLastSixMonthsView(groupedDeliveries: .constant([
        GroupedDeliveries(key: "July '24", deliveries: [
            Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, babies: [], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true)
        ]),
        GroupedDeliveries(key: "August '24", deliveries: [
            Delivery(id: "3", userId: "U3", userFirstName: "Charlie", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M3", date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, babies: [], babyCount: 3, deliveryMethod: .cSection, epiduralUsed: true)
        ])
    ]))
}
