//
//  DeliveryCalendarView.swift
//  StorkFeatureDashboard
//
//  Month calendar with a method filter and the selected day's deliveries. Rows push to a
//  delivery via `NavigationLink(value:)`, or call `onDeliverySelected` when sheet-presented.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct DeliveryCalendarView: View {
    @Bindable private var model: CalendarModel
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    private let onDeliverySelected: ((UUID) -> Void)?

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var selectedMethod: DeliveryMethod?

    private let calendar = Calendar.current

    public init(model: CalendarModel, onDeliverySelected: ((UUID) -> Void)? = nil) {
        self.model = model
        self.onDeliverySelected = onDeliverySelected
    }

    private var filteredDeliveries: [Delivery] {
        guard let method = selectedMethod else { return model.deliveries }
        return model.deliveries.filter { $0.deliveryMethod == method }
    }

    private var deliveriesForSelectedDate: [Delivery] {
        filteredDeliveries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var babyCountForSelectedDate: Int {
        deliveriesForSelectedDate.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MonthHeaderView(displayedMonth: $displayedMonth, onPrevious: { changeMonth(by: -1) }, onNext: { changeMonth(by: 1) }, onToday: goToToday)
                    .padding(.horizontal).padding(.vertical, 8)

                MethodFilterView(selectedMethod: $selectedMethod)
                    .padding(.horizontal).padding(.bottom, 8)

                CalendarGridView(displayedMonth: displayedMonth, selectedDate: $selectedDate, deliveries: filteredDeliveries)
                    .padding(.horizontal)

                Divider().padding(.top, 16)

                if deliveriesForSelectedDate.isEmpty {
                    ContentUnavailableView("No Deliveries", systemImage: "calendar.badge.checkmark",
                                           description: Text("No deliveries recorded on \(formattedDate(selectedDate))"))
                        .padding(.top, 40)
                } else {
                    SelectedDaySection(
                        deliveries: deliveriesForSelectedDate,
                        babyCount: babyCountForSelectedDate,
                        dateLabel: formattedDate(selectedDate),
                        onDeliverySelected: onDeliverySelected,
                        useDayMonthYear: useDayMonthYearDates
                    )
                }
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Calendar")
        .onAppear { model.load() }
        .task { await model.refresh() }
    }

    private struct SelectedDaySection: View {
        let deliveries: [Delivery]
        let babyCount: Int
        let dateLabel: String
        let onDeliverySelected: ((UUID) -> Void)?
        let useDayMonthYear: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text("^[\(deliveries.count) delivery](inflect: true), ^[\(babyCount) baby](inflect: true) on \(dateLabel)")
                    .font(.footnote).foregroundStyle(.secondary).textCase(.uppercase)
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)

                VStack(spacing: 0) {
                    ForEach(Array(deliveries.enumerated()), id: \.element.id) { index, delivery in
                        if index > 0 { Divider().padding(.leading, 16) }
                        Group {
                            if let onSelected = onDeliverySelected {
                                Button { onSelected(delivery.id) } label: {
                                    DeliveryCalendarRowView(delivery: delivery, useDayMonthYear: useDayMonthYear)
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink(value: delivery) {
                                    DeliveryCalendarRowView(delivery: delivery, useDayMonthYear: useDayMonthYear)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = newMonth }
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = Date(); selectedDate = Date() }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct MonthHeaderView: View {
    @Binding var displayedMonth: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var body: some View {
        HStack {
            Button(action: onPrevious) { Image(systemName: "chevron.left").font(.title3).fontWeight(.semibold) }
                .buttonStyle(.plain).accessibilityLabel("Previous month")
            Spacer()
            Text(monthYearString).font(.title2).fontWeight(.bold)
            Spacer()
            Button(action: onNext) { Image(systemName: "chevron.right").font(.title3).fontWeight(.semibold) }
                .buttonStyle(.plain).accessibilityLabel("Next month")
            Button(action: onToday) { Text("Today").font(.subheadline).fontWeight(.medium) }
                .buttonStyle(.bordered).padding(.leading, 8)
        }
    }
}

private struct MethodFilterView: View {
    @Binding var selectedMethod: DeliveryMethod?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", color: .gray, isSelected: selectedMethod == nil) { selectedMethod = nil }
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    FilterChip(label: method.displayName, color: method.accentColor, isSelected: selectedMethod == method) { selectedMethod = method }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? color.opacity(0.2) : Color.clear))
                .overlay(Capsule().strokeBorder(color, lineWidth: isSelected ? 0 : 1))
                .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct DeliveryCalendarRowView: View {
    let delivery: Delivery
    let useDayMonthYear: Bool

    private var babyCount: Int { delivery.babies?.count ?? delivery.babyCount }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(delivery.babies?.prefix(5) ?? [], id: \.id) { baby in
                    Circle().fill(baby.sex.color).frame(width: 8, height: 8)
                }
                if babyCount > 5 {
                    Text("+\(babyCount - 5)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString).font(.headline)
                Text("^[\(babyCount) baby](inflect: true) • \(delivery.deliveryMethod.displayName)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                if delivery.epiduralUsed {
                    Image(systemName: "syringe").imageScale(.small).foregroundStyle(.storkBlue).accessibilityLabel("Epidural used")
                }
                if delivery.babies?.contains(where: { $0.nicuStay }) == true {
                    Image(systemName: "cross.circle").imageScale(.small).foregroundStyle(.orange).accessibilityLabel("NICU stay")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: delivery.date)
    }
}
#endif
