//
//  YearWrapView.swift
//  StorkFeatureDashboard
//
//  "Your Year in Births": a short paged story (intro, who arrived, your role, your rhythm,
//  comparison with last year) ending in a summary card that can be shared as an image.
//  Free for everyone. Losses are never part of the story pages; they appear only as the
//  gentle "Remembered" line on the summary, and only on the shared image if the user opts in.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct WrapSelection: Identifiable, Equatable {
    let year: Int
    var id: Int { year }
}

public struct YearWrapView: View {
    @State private var model: YearWrapModel
    @State private var page: Int
    @State private var shareImage: IdentifiableImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.noteReviewMoment) private var noteReviewMoment

    public init(model: YearWrapModel) {
        _model = State(initialValue: model)
        #if DEBUG
        _page = State(initialValue: DebugLaunchOptions.wrapPage)
        #else
        _page = State(initialValue: 0)
        #endif
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let stats = model.stats {
                    TabView(selection: $page) {
                        ForEach(Array(model.pages.enumerated()), id: \.offset) { index, kind in
                            WrapPageContainer(kind: kind) {
                                pageContent(kind, stats: stats)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else {
                    ContentUnavailableView(String(localized: "No births to wrap yet", bundle: .module), systemImage: "sparkles")
                }
            }
            .background(background.ignoresSafeArea())
            .navigationTitle(Text("Your Year in Births", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done", bundle: .module)) { dismiss() }
                }
                if model.years.count > 1 {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker(String(localized: "Year", bundle: .module), selection: Binding(get: { model.year }, set: { model.select(year: $0); page = 0 })) {
                                ForEach(model.years, id: \.self) { Text(verbatim: String($0)).tag($0) }
                            }
                        } label: {
                            Label(String(model.year), systemImage: "calendar")
                        }
                    }
                }
            }
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image]) { completed in
                if completed { noteWrapMoment(.yearWrapShared) }
            }
        }
        .onChange(of: page) { _, newPage in
            if newPage == model.pages.count - 1 { noteWrapMoment(.yearWrapViewedToEnd) }
        }
        #if DEBUG
        .task { exportDebugImages() }
        #endif
    }

    private var background: some View {
        LinearGradient(colors: [Color.storkBlue.opacity(0.22), Color.storkPink.opacity(0.12), Color(uiColor: .systemBackground)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private func pageContent(_ kind: YearWrapModel.Page, stats: YearWrapStats) -> some View {
        switch kind {
        case .intro: IntroPage(stats: stats)
        case .arrivals: ArrivalsPage(stats: stats)
        case .roles: RolesPage(stats: stats)
        case .rhythm: RhythmPage(stats: stats)
        case .comparison: ComparisonPage(stats: stats)
        case .summary: SummaryPage(model: model, stats: stats) { format in
            share(stats: stats, format: format)
        }
        }
    }

    /// A year with losses ends on a screen that carries the remembrance line, so it never
    /// counts as a review moment.
    private func noteWrapMoment(_ moment: ReviewPromptPolicy.Moment) {
        guard let stats = model.stats, stats.remembrance == 0 else { return }
        noteReviewMoment(moment)
    }

    private func share(stats: YearWrapStats, format: YearWrapModel.ShareFormat) {
        Haptics.lightImpact()
        if let image = YearWrapShareRenderer.render(stats: stats, format: format, remembrance: model.remembranceForImage) {
            shareImage = IdentifiableImage(image: image)
        }
    }

    #if DEBUG
    /// `-StorkExportWrapImages 1`: write both share images to Documents/WrapShare so they can
    /// be inspected without driving the share sheet.
    private func exportDebugImages() {
        guard DebugLaunchOptions.exportWrapImages, let stats = model.stats else { return }
        if DebugLaunchOptions.wrapIncludeRemembrance { model.includeRemembranceOnImage = true }
        let folder = URL.documentsDirectory.appending(path: "WrapShare")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for format in YearWrapModel.ShareFormat.allCases {
            if let data = YearWrapShareRenderer.render(stats: stats, format: format, remembrance: model.remembranceForImage)?.pngData() {
                let suffix = model.remembranceForImage == nil ? "" : "-remembrance"
                try? data.write(to: folder.appending(path: "wrap-\(stats.year)-\(format.rawValue)\(suffix).png"))
            }
        }
    }
    #endif
}

// MARK: - Page scaffold

private struct WrapPageContainer<Content: View>: View {
    let kind: YearWrapModel.Page
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 84)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct PageTitle: View {
    let text: Text
    var body: some View {
        text.font(.system(.title2, design: .rounded, weight: .bold))
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Pages

private struct IntroPage: View {
    let stats: YearWrapStats
    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(Color.storkPink).accessibilityHidden(true)
            Text("Your Year in Births", bundle: .module)
                .font(.system(.headline, design: .rounded)).foregroundStyle(.secondary)
            Text(verbatim: String(stats.year))
                .font(.system(size: 76, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing))
            Text("^[\(stats.babies) baby](inflect: true)", bundle: .module)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
            Text("^[\(stats.deliveries) delivery](inflect: true)", bundle: .module)
                .font(.system(.title3, design: .rounded)).foregroundStyle(.secondary)
            Text("Thank you for being there.", bundle: .module)
                .font(.callout).foregroundStyle(.secondary).padding(.top, 12)
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

private struct StatTile: View {
    let color: Color
    let text: Text
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 14, height: 14).accessibilityHidden(true)
            text.font(.system(.title3, design: .rounded, weight: .semibold))
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.quaternary))
    }
}

private struct ArrivalsPage: View {
    let stats: YearWrapStats
    var body: some View {
        VStack(spacing: 20) {
            PageTitle(text: Text("Who Arrived", bundle: .module))
            MarbleMosaic(summary: stats.jar)
                .frame(height: 170)
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                StatTile(color: .storkBlue, text: Text("^[\(stats.boys) boy](inflect: true)", bundle: .module))
                StatTile(color: .storkPink, text: Text("^[\(stats.girls) girl](inflect: true)", bundle: .module))
                if stats.nurseCatches > 0 {
                    StatTile(color: .storkOrange, text: Text("^[\(stats.nurseCatches) nurse catch](inflect: true)", bundle: .module))
                }
                if stats.multipleSets > 0 {
                    StatTile(color: .secondary, text: Text("^[\(stats.multipleSets) multiple birth](inflect: true)", bundle: .module))
                }
            }
        }
    }
}

private struct RolesPage: View {
    let stats: YearWrapStats
    var body: some View {
        let top = stats.roles.first?.deliveries ?? 1
        VStack(spacing: 20) {
            PageTitle(text: Text("Your Role", bundle: .module))
            VStack(spacing: 14) {
                ForEach(stats.roles.prefix(6)) { role in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(role.role.displayName, systemImage: role.role.systemImage)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("^[\(role.deliveries) delivery](inflect: true)", bundle: .module)
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            Capsule().fill(Color.storkPurple.opacity(0.75))
                                .frame(width: max(8, geo.size.width * CGFloat(role.deliveries) / CGFloat(top)))
                        }
                        .frame(height: 8)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        }
    }
}

private struct RhythmPage: View {
    let stats: YearWrapStats

    var body: some View {
        VStack(spacing: 20) {
            PageTitle(text: Text("Your Rhythm", bundle: .module))
            MonthBars(stats: stats)
            VStack(spacing: 10) {
                if let month = stats.busiestMonth {
                    FactRow(icon: "calendar", label: Text("Busiest month", bundle: .module),
                            value: Text(verbatim: YearWrapFormat.monthName(month.monthStart)),
                            detail: Text("^[\(month.deliveries) delivery](inflect: true)", bundle: .module))
                }
                if let day = stats.busiestDay {
                    FactRow(icon: "sun.max.fill", label: Text("Busiest day", bundle: .module),
                            value: Text(verbatim: YearWrapFormat.monthDay(day.date)),
                            detail: Text("^[\(day.deliveries) delivery](inflect: true)", bundle: .module))
                }
                if stats.longestStreak > 1 {
                    FactRow(icon: "flame.fill", label: Text("Longest streak", bundle: .module),
                            value: Text("^[\(stats.longestStreak) day](inflect: true) in a row", bundle: .module), detail: nil)
                }
                if let first = stats.firstBirth {
                    FactRow(icon: "1.circle.fill", label: Text("First birth of the year", bundle: .module),
                            value: Text(verbatim: YearWrapFormat.monthDay(first)), detail: nil)
                }
                if let last = stats.lastBirth, last != stats.firstBirth {
                    FactRow(icon: "flag.checkered", label: Text("Most recent birth", bundle: .module),
                            value: Text(verbatim: YearWrapFormat.monthDay(last)), detail: nil)
                }
            }
        }
    }
}

private struct FactRow: View {
    let icon: String
    let label: Text
    let value: Text
    let detail: Text?
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color.storkOrange).frame(width: 26).accessibilityHidden(true)
            label.font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 0) {
                value.font(.subheadline.weight(.semibold))
                if let detail { detail.font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .accessibilityElement(children: .combine)
    }
}

private struct MonthBars: View {
    let stats: YearWrapStats
    var body: some View {
        let peak = max(1, stats.babiesByMonth.max() ?? 1)
        let busiest = stats.busiestMonth?.month
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<12, id: \.self) { index in
                VStack(spacing: 4) {
                    Capsule()
                        .fill(index + 1 == busiest ? Color.storkPink : Color.storkBlue.opacity(0.7))
                        .frame(height: max(4, 90 * CGFloat(stats.babiesByMonth[index]) / CGFloat(peak)))
                    Text(verbatim: YearWrapFormat.monthInitial(index + 1)).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 120, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

private struct ComparisonPage: View {
    let stats: YearWrapStats

    var body: some View {
        if let c = stats.comparison {
            let previous = String(c.previousYear)
            VStack(spacing: 22) {
                PageTitle(text: Text("Compared with \(previous)", bundle: .module))
                HStack(spacing: 14) {
                    column(year: previous, babies: c.babies, tint: .storkBlue.opacity(0.6))
                    column(year: String(stats.year), babies: stats.babies, tint: .storkPink)
                }
                Group {
                    if c.babyChange == 0 {
                        Text("The same as \(previous)", bundle: .module)
                    } else {
                        let percent = Int(abs(c.babyPercentChange ?? 0).rounded())
                        if c.babyChange > 0 {
                            Text("Up \(max(1, percent))% from \(previous)", bundle: .module)
                        } else {
                            Text("Down \(max(1, percent))% from \(previous)", bundle: .module)
                        }
                    }
                }
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.center)
            }
        }
    }

    private func column(year: String, babies: Int, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: year).font(.system(.headline, design: .rounded)).foregroundStyle(.secondary)
            Text("^[\(babies) baby](inflect: true)", bundle: .module)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tint.opacity(0.25)))
        .accessibilityElement(children: .combine)
    }
}

private struct SummaryPage: View {
    @Bindable var model: YearWrapModel
    let stats: YearWrapStats
    let onShare: (YearWrapModel.ShareFormat) -> Void

    var body: some View {
        let size = YearWrapShareView.size(for: model.shareFormat)
        let scale: CGFloat = model.shareFormat == .story ? 0.56 : 0.8
        VStack(spacing: 16) {
            PageTitle(text: Text("Your Year, Shared", bundle: .module))

            Picker(String(localized: "Format", bundle: .module), selection: $model.shareFormat) {
                Text("Story", bundle: .module).tag(YearWrapModel.ShareFormat.story)
                Text("Square", bundle: .module).tag(YearWrapModel.ShareFormat.square)
            }
            .pickerStyle(.segmented)

            YearWrapShareView(stats: stats, format: model.shareFormat, remembrance: model.remembranceForImage)
                .fixedSize()
                .scaleEffect(scale)
                .frame(width: size.width * scale, height: size.height * scale)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Preview of your shareable summary", bundle: .module))

            Button { onShare(model.shareFormat) } label: {
                Label(String(localized: "Share Image", bundle: .module), systemImage: "square.and.arrow.up")
                    .font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.storkBlue)
            .controlSize(.large)

            Text("The image has no names and no patient information.", bundle: .module)
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)

            if stats.remembrance > 0 {
                VStack(spacing: 8) {
                    Divider()
                    Label {
                        Text("Remembered: \(stats.remembrance)", bundle: .module)
                    } icon: {
                        Image(systemName: "heart.fill").foregroundStyle(Color.storkPurple.opacity(0.7))
                    }
                    .font(.subheadline.weight(.medium))
                    Toggle(isOn: $model.includeRemembranceOnImage) {
                        Text("Include on shared image", bundle: .module)
                    }
                    Text("Only you see this unless you turn it on.", bundle: .module)
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}
#endif
