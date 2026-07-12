//
//  CalendarGridView.swift
//  StorkFeatureDashboard
//
//  A month grid with per-day delivery indicator dots.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct CalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let deliveries: [Delivery]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption).fontWeight(.medium).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                // Identify by grid position, not the date: the leading/trailing blanks are all
                // nil, so `id: \.self` collides those slots to one ID (undefined layout).
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            deliveriesForDay: deliveriesOn(date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        var days: [Date?] = []
        var current = monthFirstWeek.start
        for _ in 0..<42 {
            days.append(calendar.isDate(current, equalTo: displayedMonth, toGranularity: .month) ? current : nil)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        while days.count > 7 && days.suffix(7).allSatisfy({ $0 == nil }) {
            days.removeLast(7)
        }
        return days
    }

    private func deliveriesOn(_ date: Date) -> [Delivery] {
        deliveries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let deliveriesForDay: [Delivery]
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))", bundle: .module)
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .storkPurple : .primary))

                if !deliveriesForDay.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(deliveriesForDay.prefix(3).indices, id: \.self) { index in
                            Circle().fill(dotColor(for: deliveriesForDay[index])).frame(width: 6, height: 6)
                        }
                        if deliveriesForDay.count > 3 {
                            Text("+", bundle: .module).font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Color.clear.frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.storkPurple : Color.clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func dotColor(for delivery: Delivery) -> Color {
        let babies = delivery.babies ?? []
        let hasMale = babies.contains { $0.sex == .male }
        let hasFemale = babies.contains { $0.sex == .female }
        if hasMale && hasFemale { return .storkPurple }
        if hasMale { return .storkBlue }
        if hasFemale { return .storkPink }
        return .gray
    }

    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var dateString = dateFormatter.string(from: date)
        if isToday { dateString = "Today, \(dateString)" }
        if deliveriesForDay.isEmpty { return dateString }
        let babyCount = deliveriesForDay.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        let deliveryPart = deliveriesForDay.count == 1 ? String(localized: "1 delivery", bundle: .module) : String(localized: "\(deliveriesForDay.count) deliveries", bundle: .module)
        let babyPart = babyCount == 1 ? String(localized: "1 baby", bundle: .module) : String(localized: "\(babyCount) babies", bundle: .module)
        return "\(dateString), \(deliveryPart), \(babyPart)"
    }
}
#endif
