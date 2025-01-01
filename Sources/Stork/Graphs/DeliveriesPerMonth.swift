//
//  DeliveriesPerMonth.swift
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

// MARK: - DeliveriesPerMonth View
/// A SwiftUI view that displays a line chart of deliveries per month for the last six months.
struct DeliveriesPerMonth: View {
    // MARK: - Properties
    
    /// Bindings to the grouped deliveries data, where each key is a month-year string and the value is an array of `Delivery` objects.
    @Binding var groupedDeliveries: [(key: String, value: [Delivery])]
    
    /// Processed data ready for plotting, containing the last six months.
    @State private var deliveriesLastSixMonths: [DeliveryGraphMonthData] = []
    
    /// DateFormatter to parse the month-year keys in `groupedDeliveries`.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM ''yy" // Matches the format "December '24"
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: - Body
    var body: some View {
        VStack {
            if deliveriesLastSixMonths.isEmpty {
                // Display a message when there's no data for the last six months.
                Text("No delivery data available for the past six months.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("No delivery data available for the past six months.")
            } else {
                // Title for the chart
                Text("Deliveries Per Month")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // MARK: - Line Chart
                Chart(deliveriesLastSixMonths) { monthlyData in
                    // LineMark represents the trend of deliveries over the months.
                    LineMark(
                        x: .value("Month", monthlyData.date, unit: .month),
                        y: .value("Deliveries", monthlyData.count)
                    )
                    .interpolationMethod(.catmullRom) // Smooth curve
                    .foregroundStyle(Color.blue)
                    
                    // PointMark represents individual data points.
                    PointMark(
                        x: .value("Month", monthlyData.date, unit: .month),
                        y: .value("Deliveries", monthlyData.count)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text("\(monthlyData.count)")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .accessibilityLabel("\(monthlyData.count) deliveries in \(monthlyData.month)")
                    }
                }
                .chartYAxis {
                    // Configures the Y-axis to display delivery counts.
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    // Configures the X-axis to display abbreviated month names.
                    AxisMarks(values: .stride(by: .month, count: 1)) { date in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 200) // Adjust the height as needed
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
    
    /// Aggregates the number of deliveries per month for the last six months.
    private func aggregateMonthlyDeliveries() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate the last six months' keys and corresponding first-of-month dates.
        var lastSixMonthsKeys: [String] = []
        var lastSixMonthsDates: [Date] = []
        
        for offset in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -offset, to: today) {
                let key = dateFormatter.string(from: date)
                lastSixMonthsKeys.append(key)
                
                // Get the first day of the month for accurate plotting.
                let components = calendar.dateComponents([.year, .month], from: date)
                if let firstOfMonth = calendar.date(from: components) {
                    lastSixMonthsDates.append(firstOfMonth)
                }
            }
        }
        
        // Reverse to have chronological order from oldest to newest.
        lastSixMonthsKeys.reverse()
        lastSixMonthsDates.reverse()
        
        // Initialize the aggregated data array.
        var tempAggregatedData: [DeliveryGraphMonthData] = []
        
        for (index, key) in lastSixMonthsKeys.enumerated() {
            if let deliveriesInMonth = groupedDeliveries.first(where: { $0.key == key })?.value {
                let count = deliveriesInMonth.count
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: count)
                tempAggregatedData.append(monthData)
            } else {
                // If no deliveries for the month, count is 0.
                let date = lastSixMonthsDates[index]
                let monthData = DeliveryGraphMonthData(month: key, date: date, count: 0)
                tempAggregatedData.append(monthData)
            }
        }
        
        // Assign to the state variable.
        self.deliveriesLastSixMonths = tempAggregatedData
    }
}

// MARK: - Preview
struct DeliveriesPerMonth_Previews: PreviewProvider {
    static var previews: some View {
        DeliveriesPerMonth(groupedDeliveries: .constant([
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


// MARK: - Preview
#Preview {
    DeliveriesPerMonth(groupedDeliveries: .constant([]))
}

#endif
