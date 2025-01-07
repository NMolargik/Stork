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
    
    @Binding var groupedDeliveries: [(key: String, value: [Delivery])]
    
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
            if deliveriesLastSix.isEmpty {
                Text("No delivery data available for the past six months.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("No delivery data available for the past six months.")
            } else {
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
                            colors: [Color.indigo, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Month", monthlyData.date, unit: .month),
                        y: .value("Deliveries", monthlyData.count)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color.indigo)
                    
                    PointMark(
                        x: .value("Month", monthlyData.date, unit: .month),
                        y: .value("Deliveries", monthlyData.count)
                    )
                    .foregroundStyle(Color.orange)
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
            
            Spacer()
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
            if let deliveriesInMonth = groupedDeliveries.first(where: { $0.key == key })?.value {
                let count = deliveriesInMonth.count
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

// MARK: - Preview
struct DeliveriesLastSixMonthsView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveriesLastSixMonthsView(groupedDeliveries: .constant([
            // Sample data for preview purposes
            (key: "July '24", value: [
                Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, babies: [], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true),
                Delivery(id: "2", userId: "U2", userFirstName: "Bob", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2", date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, babies: [], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
            ]),
            (key: "August '24", value: [
                Delivery(id: "3", userId: "U3", userFirstName: "Charlie", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M3", date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, babies: [], babyCount: 3, deliveryMethod: .cSection, epiduralUsed: true)
            ]),
            (key: "September '24", value: [
                Delivery(id: "4", userId: "U4", userFirstName: "Diana", hospitalId: "H3", hospitalName: "County Hospital", musterId: "M4", date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, babies: [], babyCount: 1, deliveryMethod: .vBac, epiduralUsed: false)
            ]),
            (key: "October '24", value: [
                Delivery(id: "5", userId: "U5", userFirstName: "Ethan", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M5", date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, babies: [], babyCount: 2, deliveryMethod: .cSection, epiduralUsed: true)
            ]),
            (key: "November '24", value: []),
            (key: "December '24", value: [
                Delivery(id: "6", userId: "U6", userFirstName: "Fiona", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M6", date: Date(), babies: [], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
            ])
        ]))
    }
}

#endif
