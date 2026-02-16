//
//  DeliveryCalendarView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

/// Calendar view showing deliveries by month with day selection.
struct DeliveryCalendarView: View {
    @Environment(DeliveryManager.self) private var deliveryManager
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false

    /// Optional callback for when a delivery is selected (used when presented in a sheet)
    var onDeliverySelected: ((UUID) -> Void)? = nil

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var selectedMethod: DeliveryMethod? = nil

    private let calendar = Calendar.current

    private var filteredDeliveries: [Delivery] {
        var deliveries = deliveryManager.deliveries

        // Filter by selected method if any
        if let method = selectedMethod {
            deliveries = deliveries.filter { $0.deliveryMethod == method }
        }

        return deliveries
    }

    private var deliveriesForSelectedDate: [Delivery] {
        filteredDeliveries.filter { delivery in
            calendar.isDate(delivery.date, inSameDayAs: selectedDate)
        }
    }

    private var babyCountForSelectedDate: Int {
        deliveriesForSelectedDate.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Month navigation header
                MonthHeaderView(
                    displayedMonth: $displayedMonth,
                    onPrevious: { changeMonth(by: -1) },
                    onNext: { changeMonth(by: 1) },
                    onToday: { goToToday() }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Method filter
                MethodFilterView(selectedMethod: $selectedMethod)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                // Calendar grid
                CalendarGridView(
                    displayedMonth: displayedMonth,
                    selectedDate: $selectedDate,
                    deliveries: filteredDeliveries
                )
                .padding(.horizontal)

                Divider()
                    .padding(.top, 16)

                // Selected day deliveries
                if deliveriesForSelectedDate.isEmpty {
                    ContentUnavailableView(
                        "No Deliveries",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("No deliveries recorded on \(formattedDate(selectedDate))")
                    )
                    .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(deliveriesForSelectedDate.count) deliver\(deliveriesForSelectedDate.count == 1 ? "y" : "ies"), \(babyCountForSelectedDate) bab\(babyCountForSelectedDate == 1 ? "y" : "ies") on \(formattedDate(selectedDate))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(deliveriesForSelectedDate.enumerated()), id: \.element.id) { index, delivery in
                                if index > 0 {
                                    Divider()
                                        .padding(.leading, 16)
                                }

                                Group {
                                    if let onSelected = onDeliverySelected {
                                        Button {
                                            onSelected(delivery.id)
                                        } label: {
                                            DeliveryCalendarRowView(
                                                delivery: delivery,
                                                useDayMonthYear: useDayMonthYearDates
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        NavigationLink(value: delivery.id) {
                                            DeliveryCalendarRowView(
                                                delivery: delivery,
                                                useDayMonthYear: useDayMonthYearDates
                                            )
                                        }
                                        .foregroundStyle(.primary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Calendar")
        .task {
            await deliveryManager.refresh()
        }
    }

    // MARK: - Navigation

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Month Header View

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
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")

            Button(action: onToday) {
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .padding(.leading, 8)
        }
    }
}

// MARK: - Method Filter View

private struct MethodFilterView: View {
    @Binding var selectedMethod: DeliveryMethod?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                FilterChip(
                    label: "All",
                    color: .gray,
                    isSelected: selectedMethod == nil,
                    onTap: { selectedMethod = nil }
                )

                // Method chips
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    FilterChip(
                        label: method.rawValue,
                        color: colorForMethod(method),
                        isSelected: selectedMethod == method,
                        onTap: { selectedMethod = method }
                    )
                }
            }
        }
    }

    private func colorForMethod(_ method: DeliveryMethod) -> Color {
        switch method {
        case .vaginal:
            return .storkPink
        case .cSection:
            return .storkBlue
        case .vBac:
            return .storkPurple
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(color, lineWidth: isSelected ? 0 : 1)
                )
                .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Delivery Calendar Row View

private struct DeliveryCalendarRowView: View {
    let delivery: Delivery
    let useDayMonthYear: Bool

    private var babyCount: Int {
        delivery.babies?.count ?? delivery.babyCount
    }

    var body: some View {
        HStack(spacing: 12) {
            // Sex indicator dots
            HStack(spacing: 4) {
                ForEach(delivery.babies?.prefix(5) ?? [], id: \.id) { baby in
                    Circle()
                        .fill(colorForSex(baby.sex))
                        .frame(width: 8, height: 8)
                }
                if babyCount > 5 {
                    Text("+\(babyCount - 5)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Time
                Text(timeString)
                    .font(.headline)

                // Baby summary
                Text("\(babyCount) bab\(babyCount == 1 ? "y" : "ies") \u{2022} \(delivery.deliveryMethod.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Indicators
            HStack(spacing: 8) {
                if delivery.epiduralUsed {
                    Image(systemName: "syringe")
                        .imageScale(.small)
                        .foregroundStyle(.storkBlue)
                }
                if delivery.babies?.contains(where: { $0.nicuStay }) == true {
                    Image(systemName: "cross.circle")
                        .imageScale(.small)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: delivery.date)
    }

    private func colorForSex(_ sex: Sex) -> Color {
        switch sex {
        case .male:
            return .storkBlue
        case .female:
            return .storkPink
        case .loss:
            return .gray
        }
    }
}

#Preview("Calendar View") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    return NavigationStack {
        DeliveryCalendarView()
    }
    .environment(DeliveryManager(context: context))
}
