//
//  CalendarGridView.swift
//  StorkFeatureDashboard
//
//  A month grid with per-day delivery indicator dots, or — Stork Pro — a heat map that
//  shades each day by how many deliveries it holds relative to the busiest day shown.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct CalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let deliveries: [Delivery]
    var showsHeatMap: Bool = false

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
                let busiestDay = maxDeliveriesInMonth()
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date {
                        let dayDeliveries = deliveriesOn(date)
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            deliveriesForDay: dayDeliveries,
                            heatIntensity: showsHeatMap ? heatIntensity(count: dayDeliveries.count, max: busiestDay) : nil,
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

    private func maxDeliveriesInMonth() -> Int {
        var counts: [Date: Int] = [:]
        for delivery in deliveries where calendar.isDate(delivery.date, equalTo: displayedMonth, toGranularity: .month) {
            counts[calendar.startOfDay(for: delivery.date), default: 0] += 1
        }
        return counts.values.max() ?? 0
    }

    /// 0 for an empty day, otherwise 0.25…1 scaled against the month's busiest day.
    static func heatIntensity(count: Int, max: Int) -> Double {
        guard count > 0, max > 0 else { return 0 }
        return 0.25 + 0.75 * (Double(count) / Double(max))
    }

    private func heatIntensity(count: Int, max: Int) -> Double {
        Self.heatIntensity(count: count, max: max)
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let deliveriesForDay: [Delivery]
    /// Heat-map shading (0…1) when the Pro heat map is on; `nil` draws dots.
    var heatIntensity: Double? = nil
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var heatFill: Color? {
        guard let heatIntensity, heatIntensity > 0, !isSelected else { return nil }
        return Color.storkPurple.opacity(heatIntensity * 0.85)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))", bundle: .module)
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected || (heatIntensity ?? 0) > 0.6 ? .white : (isToday ? .storkPurple : .primary))

                if heatIntensity != nil {
                    if !deliveriesForDay.isEmpty {
                        Text("\(deliveriesForDay.count)", bundle: .module)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isSelected || (heatIntensity ?? 0) > 0.6 ? .white.opacity(0.9) : .secondary)
                            .frame(height: 6)
                    } else {
                        Color.clear.frame(height: 6)
                    }
                } else if !deliveriesForDay.isEmpty {
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
            .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.storkPurple : (heatFill ?? Color.clear)))
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
