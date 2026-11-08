//
//  YearWrapShareView.swift
//  StorkFeatureDashboard
//
//  The shareable Year Wrap summary, drawn at a fixed point size (360 wide) and rendered
//  by `ImageRenderer` at 3x: 1080x1080 for the square and 1080x1920 for the story. It
//  carries aggregate numbers only: no names, no notes, no dates finer than a month, and
//  no patient data of any kind. The optional remembrance line is the only mention of a
//  loss and appears only when the user turns it on.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct YearWrapShareView: View {
    let stats: YearWrapStats
    let format: YearWrapModel.ShareFormat
    /// Non-nil only when the user chose to include the remembrance line.
    let remembrance: Int?

    static func size(for format: YearWrapModel.ShareFormat) -> CGSize {
        switch format {
        case .square: CGSize(width: 360, height: 360)
        case .story: CGSize(width: 360, height: 640)
        }
    }

    private var isStory: Bool { format == .story }

    var body: some View {
        let size = Self.size(for: format)
        VStack(spacing: isStory ? 16 : 8) {
            VStack(spacing: isStory ? 2 : 0) {
                Text("My Year in Births", bundle: .module)
                    .font(.system(size: isStory ? 15 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.storkPurple)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text(verbatim: String(stats.year))
                    .font(.system(size: isStory ? 64 : 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing))
            }

            VStack(spacing: 0) {
                Text("^[\(stats.babies) baby](inflect: true)", bundle: .module)
                    .font(.system(size: isStory ? 34 : 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("^[\(stats.deliveries) delivery](inflect: true)", bundle: .module)
                    .font(.system(size: isStory ? 17 : 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            MarbleMosaic(summary: stats.jar)
                .frame(maxWidth: .infinity)
                .frame(height: isStory ? 250 : 84)
                .accessibilityHidden(true)

            FlowLayout(spacing: 6) {
                chip(color: .storkBlue, text: Text("^[\(stats.boys) boy](inflect: true)", bundle: .module))
                chip(color: .storkPink, text: Text("^[\(stats.girls) girl](inflect: true)", bundle: .module))
                if stats.nurseCatches > 0 {
                    chip(color: .storkOrange, text: Text("^[\(stats.nurseCatches) nurse catch](inflect: true)", bundle: .module))
                }
                if stats.multipleSets > 0 {
                    chip(color: .secondary, text: Text("^[\(stats.multipleSets) multiple birth](inflect: true)", bundle: .module))
                }
            }
            .frame(maxWidth: .infinity)

            if isStory, let month = stats.busiestMonth {
                Text("Busiest month: \(YearWrapFormat.monthName(month.monthStart))", bundle: .module)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if let remembrance {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").foregroundStyle(Color.storkPurple.opacity(0.7)).accessibilityHidden(true)
                    Text("Remembered: \(remembrance)", bundle: .module)
                }
                .font(.system(size: isStory ? 14 : 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            YearWrapWordmark()
        }
        .padding(isStory ? 28 : 20)
        .frame(width: size.width, height: size.height)
        .background(
            ZStack {
                Color.white
                LinearGradient(colors: [Color.storkBlue.opacity(0.22), Color.storkPink.opacity(0.14), Color.storkPurple.opacity(0.10)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .environment(\.colorScheme, .light)
    }

    private func chip(color: Color, text: Text) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            text.font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.06)))
    }
}

/// Small Stork wordmark for the foot of shared images.
struct YearWrapWordmark: View {
    var body: some View {
        HStack(spacing: 5) {
            Image("stork").renderingMode(.template).resizable().scaledToFit().frame(width: 16, height: 16).accessibilityHidden(true)
            Text(verbatim: "Stork")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.storkPurple.opacity(0.85))
    }
}

/// One circle per baby born, colored like the marble jar (boy, girl, nurse catch). Sized
/// so every marble fits the available area, whatever the count.
struct MarbleMosaic: View {
    let summary: JarSummary

    private var marbles: [Color] {
        Array(repeating: Color.storkBlue, count: summary.boy)
        + Array(repeating: Color.storkPink, count: summary.girl)
        + Array(repeating: Color.storkOrange, count: summary.nurseCatch)
    }

    var body: some View {
        Canvas { context, size in
            let items = marbles
            guard !items.isEmpty, size.width > 0, size.height > 0 else { return }
            // Largest diameter whose grid still holds every marble.
            var d = min(22, sqrt(size.width * size.height / CGFloat(items.count)))
            var cols = max(1, Int(size.width / d))
            while d > 2, CGFloat((items.count + cols - 1) / cols) * d > size.height {
                d -= 0.5
                cols = max(1, Int(size.width / d))
            }
            let rows = (items.count + cols - 1) / cols
            let gridWidth = CGFloat(min(cols, items.count)) * d
            let originX = (size.width - gridWidth) / 2
            let originY = (size.height - CGFloat(rows) * d) / 2
            for (i, color) in items.enumerated() {
                let row = i / cols, col = i % cols
                let rect = CGRect(x: originX + CGFloat(col) * d + d * 0.06, y: originY + CGFloat(row) * d + d * 0.06, width: d * 0.88, height: d * 0.88)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.88)))
            }
        }
    }
}

enum YearWrapShareRenderer {
    /// Renders the share image at 3x (1080 wide). Free for everyone.
    @MainActor
    static func render(stats: YearWrapStats, format: YearWrapModel.ShareFormat, remembrance: Int?) -> UIImage? {
        let renderer = ImageRenderer(content: YearWrapShareView(stats: stats, format: format, remembrance: remembrance))
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

enum YearWrapFormat {
    static func monthName(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMM")
        return df.string(from: date)
    }

    static func monthDay(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMMMd")
        return df.string(from: date)
    }

    static func monthInitial(_ month: Int) -> String {
        let df = DateFormatter()
        df.locale = .current
        let symbols = df.veryShortStandaloneMonthSymbols ?? []
        return symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
    }
}
#endif
