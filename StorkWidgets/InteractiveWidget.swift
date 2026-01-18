//
//  InteractiveWidget.swift
//  StorkWidgets
//
//  Created by Nick Molargik on 1/17/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Interactive Widget Entry
struct InteractiveWidgetEntry: TimelineEntry {
    let date: Date
    let todayBabies: Int
    let todayDeliveries: Int
    let weeklyBabies: Int
}

// MARK: - Interactive Widget Provider
struct InteractiveWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> InteractiveWidgetEntry {
        InteractiveWidgetEntry(date: Date(), todayBabies: 3, todayDeliveries: 2, weeklyBabies: 12)
    }

    func getSnapshot(in context: Context, completion: @escaping (InteractiveWidgetEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchInteractiveData()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InteractiveWidgetEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchInteractiveData()
            // Refresh every 15 minutes for more responsive updates
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }

    @MainActor
    private func fetchInteractiveData() -> InteractiveWidgetEntry {
        do {
            let container = try widgetModelContainer()
            let context = ModelContext(container)

            let now = Date()
            let calendar = Calendar.current

            // Today's data
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            var todayDesc = FetchDescriptor<Delivery>()
            todayDesc.predicate = #Predicate<Delivery> { d in
                d.date >= startOfToday && d.date < endOfToday
            }
            let todayDeliveries = try context.fetch(todayDesc)
            let todayBabies = todayDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            // Weekly data
            let week = currentWeekRange(now: now)
            let weekStart = week.start
            let weekEnd = week.end
            var weekDesc = FetchDescriptor<Delivery>()
            weekDesc.predicate = #Predicate<Delivery> { d in
                d.date >= weekStart && d.date < weekEnd
            }
            let weekDeliveries = try context.fetch(weekDesc)
            let weeklyBabies = weekDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            return InteractiveWidgetEntry(
                date: now,
                todayBabies: todayBabies,
                todayDeliveries: todayDeliveries.count,
                weeklyBabies: weeklyBabies
            )
        } catch {
            return InteractiveWidgetEntry(date: Date(), todayBabies: 0, todayDeliveries: 0, weeklyBabies: 0)
        }
    }
}

// MARK: - Interactive Widget Small View
struct InteractiveSmallView: View {
    let entry: InteractiveWidgetEntry

    var body: some View {
        Link(destination: URL(string: "stork://new-delivery")!) {
            VStack(spacing: 8) {
                // Stats
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(entry.todayBabies)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Week")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(entry.weeklyBabies)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Quick Start Button
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Delivery")
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.storkBlue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Interactive Widget Medium View
struct InteractiveMediumView: View {
    let entry: InteractiveWidgetEntry

    var body: some View {
        Link(destination: URL(string: "stork://new-delivery")!) {
            HStack(spacing: 16) {
                // Left side - Stats
                VStack(alignment: .leading, spacing: 12) {
                    Image("storkicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(entry.todayBabies)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("babies")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("This Week")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(entry.weeklyBabies)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("babies")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Right side - Quick Actions
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                    Text("New")
                        .font(.caption2.bold())
                }
                .frame(width: 70, height: 70)
                .background(.storkBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Interactive Widget
struct QuickStartWidget: Widget {
    let kind: String = "QuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InteractiveWidgetProvider()) { entry in
            QuickStartWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Start")
        .description("View stats and quickly start a new delivery.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickStartWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: InteractiveWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            InteractiveSmallView(entry: entry)
        case .systemMedium:
            InteractiveMediumView(entry: entry)
        default:
            InteractiveSmallView(entry: entry)
        }
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    QuickStartWidget()
} timeline: {
    InteractiveWidgetEntry(date: .now, todayBabies: 3, todayDeliveries: 2, weeklyBabies: 12)
}

#Preview("Medium", as: .systemMedium) {
    QuickStartWidget()
} timeline: {
    InteractiveWidgetEntry(date: .now, todayBabies: 3, todayDeliveries: 2, weeklyBabies: 12)
}
