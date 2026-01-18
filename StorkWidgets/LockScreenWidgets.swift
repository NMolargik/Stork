//
//  LockScreenWidgets.swift
//  StorkWidgets
//
//  Created by Nick Molargik on 1/17/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Lock Screen Entry
struct LockScreenEntry: TimelineEntry {
    let date: Date
    let weeklyBabies: Int
    let todayBabies: Int
    let careerTotal: Int
}

// MARK: - Lock Screen Provider
struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), weeklyBabies: 12, todayBabies: 3, careerTotal: 1234)
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchLockScreenData()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchLockScreenData()
            // Refresh at midnight
            let calendar = Calendar.current
            let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
            let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
            completion(timeline)
        }
    }

    @MainActor
    private func fetchLockScreenData() -> LockScreenEntry {
        do {
            let container = try widgetModelContainer()
            let context = ModelContext(container)

            let now = Date()
            let calendar = Calendar.current

            // Today's babies
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            var todayDesc = FetchDescriptor<Delivery>()
            todayDesc.predicate = #Predicate<Delivery> { d in
                d.date >= startOfToday && d.date < endOfToday
            }
            let todayDeliveries = try context.fetch(todayDesc)
            let todayBabies = todayDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            // Weekly babies
            let week = currentWeekRange(now: now)
            let weekStart = week.start
            let weekEnd = week.end
            var weekDesc = FetchDescriptor<Delivery>()
            weekDesc.predicate = #Predicate<Delivery> { d in
                d.date >= weekStart && d.date < weekEnd
            }
            let weekDeliveries = try context.fetch(weekDesc)
            let weeklyBabies = weekDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            // Career total
            let allDesc = FetchDescriptor<Delivery>()
            let allDeliveries = try context.fetch(allDesc)
            let careerTotal = allDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }

            return LockScreenEntry(
                date: now,
                weeklyBabies: weeklyBabies,
                todayBabies: todayBabies,
                careerTotal: careerTotal
            )
        } catch {
            return LockScreenEntry(date: Date(), weeklyBabies: 0, todayBabies: 0, careerTotal: 0)
        }
    }
}

// MARK: - Circular Lock Screen View (iOS 16+)
struct CircularLockScreenView: View {
    let entry: LockScreenEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image("storkicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .opacity(0.6)
                
                Text("\(entry.weeklyBabies)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Rectangular Lock Screen View (iOS 16+)
struct RectangularLockScreenView: View {
    let entry: LockScreenEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Image("storkicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .opacity(0.6)

                HStack(spacing: 4) {
                    Text("\(entry.weeklyBabies)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("this week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(entry.todayBabies)")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Inline Lock Screen View
struct InlineLockScreenView: View {
    let entry: LockScreenEntry

    var body: some View {
        Label {
            Text("\(entry.weeklyBabies) babies this week")
        } icon: {
            Image("storkicon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .opacity(0.6)
        }
    }
}

// MARK: - Lock Screen Weekly Widget
struct LockScreenWeeklyWidget: Widget {
    let kind: String = "LockScreenWeeklyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weekly Babies")
        .description("Babies delivered this week on your lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct LockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LockScreenEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            CircularLockScreenView(entry: entry)
        }
    }
}

// MARK: - Career Total Lock Screen Widget
struct CareerTotalLockScreenWidget: Widget {
    let kind: String = "CareerTotalLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            CareerTotalLockScreenEntryView(entry: entry)
        }
        .configurationDisplayName("Career Total")
        .description("Your lifetime baby count on the lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

struct CareerTotalLockScreenEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LockScreenEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CareerCircularView(entry: entry)
        case .accessoryInline:
            CareerInlineView(entry: entry)
        default:
            CareerCircularView(entry: entry)
        }
    }
}

struct CareerCircularView: View {
    let entry: LockScreenEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.careerTotal)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                Text("total")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CareerInlineView: View {
    let entry: LockScreenEntry

    var body: some View {
        Label {
            Text("\(entry.careerTotal) career babies")
        } icon: {
            Image("storkicon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .opacity(0.6)
        }
    }
}

// MARK: - Previews
#Preview("Circular", as: .accessoryCircular) {
    LockScreenWeeklyWidget()
} timeline: {
    LockScreenEntry(date: .now, weeklyBabies: 12, todayBabies: 3, careerTotal: 1234)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenWeeklyWidget()
} timeline: {
    LockScreenEntry(date: .now, weeklyBabies: 12, todayBabies: 3, careerTotal: 1234)
}

#Preview("Inline", as: .accessoryInline) {
    LockScreenWeeklyWidget()
} timeline: {
    LockScreenEntry(date: .now, weeklyBabies: 12, todayBabies: 3, careerTotal: 1234)
}

#Preview("Career Circular", as: .accessoryCircular) {
    CareerTotalLockScreenWidget()
} timeline: {
    LockScreenEntry(date: .now, weeklyBabies: 12, todayBabies: 3, careerTotal: 1234)
}
