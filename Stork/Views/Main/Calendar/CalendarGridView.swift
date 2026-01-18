//
//  CalendarGridView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

/// A month grid component showing days with delivery indicators.
struct CalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let deliveries: [Delivery]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            deliveriesForDay: deliveriesOn(date),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    } else {
                        // Empty cell for days outside the month
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns an array of optional Dates for the month grid.
    /// Nil values represent days from adjacent months (leading/trailing).
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var current = monthFirstWeek.start

        // Generate 6 weeks (42 days) to ensure we cover all months
        for _ in 0..<42 {
            if calendar.isDate(current, equalTo: displayedMonth, toGranularity: .month) {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        // Trim trailing empty rows
        while days.count > 7 && days.suffix(7).allSatisfy({ $0 == nil }) {
            days.removeLast(7)
        }

        return days
    }

    /// Returns deliveries that occurred on the given date.
    private func deliveriesOn(_ date: Date) -> [Delivery] {
        deliveries.filter { delivery in
            calendar.isDate(delivery.date, inSameDayAs: date)
        }
    }
}

// MARK: - Day Cell

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
                Text("\(calendar.component(.day, from: date))")
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .storkPurple : .primary))

                // Delivery indicator dots
                if !deliveriesForDay.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(deliveriesForDay.prefix(3).indices, id: \.self) { index in
                            Circle()
                                .fill(dotColor(for: deliveriesForDay[index]))
                                .frame(width: 6, height: 6)
                        }
                        if deliveriesForDay.count > 3 {
                            Text("+")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // Placeholder to maintain consistent height
                    Color.clear.frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.storkPurple : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func dotColor(for delivery: Delivery) -> Color {
        // Color based on baby sex distribution
        let babies = delivery.babies ?? []
        let hasMale = babies.contains { $0.sex == .male }
        let hasFemale = babies.contains { $0.sex == .female }

        if hasMale && hasFemale {
            return .storkPurple
        } else if hasMale {
            return .storkBlue
        } else if hasFemale {
            return .storkPink
        } else {
            return .gray
        }
    }

    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: date)

        if deliveriesForDay.isEmpty {
            return dateString
        } else {
            let babyCount = deliveriesForDay.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
            return "\(dateString), \(deliveriesForDay.count) deliver\(deliveriesForDay.count == 1 ? "y" : "ies"), \(babyCount) bab\(babyCount == 1 ? "y" : "ies")"
        }
    }
}

#Preview("Calendar Grid") {
    CalendarGridView(
        displayedMonth: Date(),
        selectedDate: .constant(Date()),
        deliveries: []
    )
    .padding()
}
