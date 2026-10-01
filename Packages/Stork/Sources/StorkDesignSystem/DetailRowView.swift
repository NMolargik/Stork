//
//  DetailRowView.swift
//  StorkDesignSystem
//
//  A reusable row in two styles: a prominent `.feature` row and a compact `.insight`
//  row with an optional trailing accessory.
//

import SwiftUI

public struct DetailRowView<Trailing: View>: View {
    public enum Style { case feature, insight }

    private let style: Style
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let tint: Color
    @ContentBuilder private let trailing: () -> Trailing

    public init(
        style: Style,
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        tint: Color,
        @ContentBuilder trailing: @escaping () -> Trailing
    ) {
        self.style = style
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.trailing = trailing
    }

    public var body: some View {
        switch style {
        case .feature:
            FeatureRowBody(systemImage: systemImage, title: title, tint: tint)
        case .insight:
            InsightRowBody(systemImage: systemImage, title: title, subtitle: subtitle, tint: tint, trailing: trailing)
        }
    }
}

public extension DetailRowView where Trailing == EmptyView {
    /// Convenience for rows without a trailing accessory.
    init(
        style: Style,
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        tint: Color
    ) {
        self.init(
            style: style,
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            tint: tint,
            trailing: { EmptyView() }
        )
    }
}

private struct FeatureRowBody: View {
    let systemImage: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            LeadingCircle(systemImage: systemImage, tint: tint,
                          size: 44, iconSize: 40, font: .title3, backgroundOpacity: 0.18, hierarchical: true)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private struct InsightRowBody<Trailing: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String?
    let tint: Color
    let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.12))
                Image(systemName: systemImage)
                    .symbolVariant(.fill)
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline).bold()
                    .minimumScaleFactor(0.9)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                trailing()
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LeadingCircle: View {
    let systemImage: String
    let tint: Color
    let size: CGFloat
    let iconSize: CGFloat
    let font: Font
    let backgroundOpacity: Double
    let hierarchical: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(backgroundOpacity))
                .frame(width: size, height: size)
            Image(systemName: systemImage)
                .frame(width: iconSize, height: iconSize)
                .font(font)
                .foregroundStyle(tint)
                .modifier(SymbolRenderingModifier(hierarchical: hierarchical))
        }
    }
}

private struct SymbolRenderingModifier: ViewModifier {
    let hierarchical: Bool
    func body(content: Content) -> some View {
        if hierarchical {
            content.symbolRenderingMode(.hierarchical)
        } else {
            content
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        DetailRowView(style: .feature, systemImage: "heart.fill", title: "Feature Row", tint: .storkPink)
        DetailRowView(style: .insight, systemImage: "chart.bar.fill", title: "Insight Row", subtitle: "With a subtitle", tint: .storkBlue) {
            Text("12", bundle: .module).bold()
        }
    }
    .padding()
}
#endif
