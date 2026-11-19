//
//  PDFReportGenerator.swift
//  StorkFeatureExport
//
//  Renders a US-Letter PDF summary (totals, method breakdown, sex distribution).
//

#if os(iOS)
import Foundation
import UIKit
import SwiftUI
import StorkCore
import StorkDesignSystem

@MainActor
public final class PDFReportGenerator {

    public struct Configuration {
        public let deliveries: [Delivery]
        public let dateRange: ExportDateRange
        public let customDateInterval: DateInterval?
        public let useMetricUnits: Bool
        public let useDayMonthYearDates: Bool

        public init(deliveries: [Delivery], dateRange: ExportDateRange, customDateInterval: DateInterval?, useMetricUnits: Bool, useDayMonthYearDates: Bool) {
            self.deliveries = deliveries
            self.dateRange = dateRange
            self.customDateInterval = customDateInterval
            self.useMetricUnits = useMetricUnits
            self.useDayMonthYearDates = useDayMonthYearDates
        }
    }

    private let pageWidth: CGFloat = 612
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50
    private var contentWidth: CGFloat { pageWidth - (margin * 2) }

    public init() {}

    /// The app's colours for the page: always the light appearance, whatever the device shows.
    private static func ui(_ color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    public func generate(configuration: Configuration, progressCallback: ((Double) -> Void)? = nil) async throws -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())

        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            y = drawHeader(config: configuration, yPosition: y); progressCallback?(0.2)
            y = drawSummaryStats(config: configuration, yPosition: y); progressCallback?(0.4)
            y = drawDeliveryMethodSection(config: configuration, yPosition: y); progressCallback?(0.6)
            if y > pageHeight - 250 { context.beginPage(); y = margin }
            y = drawSexDistributionSection(config: configuration, yPosition: y); progressCallback?(0.7)
            if y > pageHeight - 200 { context.beginPage(); y = margin }
            _ = drawRoleSection(config: configuration, yPosition: y); progressCallback?(0.8)
            drawFooter(yPosition: pageHeight - margin); progressCallback?(1.0)
        }
    }

    private func drawHeader(config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        // The jar mark beside the title, drawn from the same code the app uses.
        var titleX = margin
        let markRenderer = ImageRenderer(content: StorkMark().frame(width: 40, height: 40))
        markRenderer.scale = 4
        if let mark = markRenderer.uiImage {
            mark.draw(in: CGRect(x: margin, y: y - 2, width: 40, height: 40))
            titleX += 50
        }
        "Delivery Report".draw(at: CGPoint(x: titleX, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.black])
        y += 36
        dateRangeDescription(config: config).draw(at: CGPoint(x: titleX, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.darkGray])
        y += 30
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: margin, y: y))
        divider.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.lightGray.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
        return y + 20
    }

    private func drawSummaryStats(config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        "Summary".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.black])
        y += 28
        let deliveries = config.deliveries
        let totalDeliveries = deliveries.count
        let totalBabies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        let epiduralCount = deliveries.count { $0.epiduralUsed }
        let epiduralPercent = totalDeliveries > 0 ? Double(epiduralCount) / Double(totalDeliveries) * 100 : 0
        let stats = [
            ("Total Deliveries", "\(totalDeliveries)", Self.ui(.storkBlue)),
            ("Total Babies", "\(totalBabies)", Self.ui(.storkPink).darkened(by: 0.35)),
            ("Epidural Usage", String(format: "%.1f%%", epiduralPercent), Self.ui(.storkOrange)),
        ]
        let statWidth = contentWidth / CGFloat(stats.count)
        for (index, stat) in stats.enumerated() {
            drawStatBox(label: stat.0, value: stat.1, color: stat.2, at: CGPoint(x: margin + CGFloat(index) * statWidth, y: y), width: statWidth - 10)
        }
        return y + 70
    }

    private func drawStatBox(label: String, value: String, color: UIColor, at point: CGPoint, width: CGFloat) {
        let path = UIBezierPath(roundedRect: CGRect(x: point.x, y: point.y, width: width, height: 50), cornerRadius: 8)
        color.setFill()
        path.fill()
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22, weight: .bold), .foregroundColor: UIColor.white]
        let valueSize = value.size(withAttributes: valueAttrs)
        value.draw(at: CGPoint(x: point.x + (width - valueSize.width) / 2, y: point.y + 8), withAttributes: valueAttrs)
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.white]
        let labelSize = label.size(withAttributes: labelAttrs)
        label.draw(at: CGPoint(x: point.x + (width - labelSize.width) / 2, y: point.y + 32), withAttributes: labelAttrs)
    }

    private func drawDeliveryMethodSection(config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        "Delivery Methods".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.black])
        y += 28
        let deliveries = config.deliveries
        let total = deliveries.count
        guard total > 0 else { return y }
        let methods = [
            ("Vaginal", deliveries.count { $0.deliveryMethod == .vaginal }, Self.ui(DeliveryMethod.vaginal.accentColor)),
            ("C-Section", deliveries.count { $0.deliveryMethod == .cSection }, Self.ui(DeliveryMethod.cSection.accentColor)),
            ("VBAC", deliveries.count { $0.deliveryMethod == .vBac }, Self.ui(DeliveryMethod.vBac.accentColor)),
        ]
        let barHeight: CGFloat = 24
        var xOffset: CGFloat = margin
        for (_, count, color) in methods {
            let barWidth = contentWidth * CGFloat(Double(count) / Double(total))
            let path = UIBezierPath(roundedRect: CGRect(x: xOffset, y: y, width: max(barWidth, 0), height: barHeight), cornerRadius: 4)
            color.setFill()
            path.fill()
            xOffset += barWidth
        }
        y += barHeight + 16
        for (name, count, color) in methods {
            let percent = Double(count) / Double(total) * 100
            UIBezierPath(ovalIn: CGRect(x: margin, y: y + 2, width: 10, height: 10)).fill(with: color)
            "\(name): \(count) (\(String(format: "%.1f", percent))%)".draw(at: CGPoint(x: margin + 16, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black])
            y += 18
        }
        return y + 16
    }

    private func drawSexDistributionSection(config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        "Baby Sex Distribution".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.black])
        y += 28
        let allBabies = config.deliveries.flatMap { $0.babies ?? [] }
        let total = allBabies.count
        guard total > 0 else { return y }
        let sexes = [
            ("Boys", allBabies.count { $0.sex == .male }, Self.ui(Sex.male.color)),
            ("Girls", allBabies.count { $0.sex == .female }, Self.ui(Sex.female.color)),
            ("Loss", allBabies.count { $0.sex == .loss }, Self.ui(Sex.loss.color)),
        ]
        for (name, count, color) in sexes {
            let percent = Double(count) / Double(total) * 100
            UIBezierPath(ovalIn: CGRect(x: margin, y: y + 2, width: 10, height: 10)).fill(with: color)
            "\(name): \(count) (\(String(format: "%.1f", percent))%)".draw(at: CGPoint(x: margin + 16, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black])
            y += 18
        }
        return y + 16
    }

    private func roleLine(_ stat: DeliveryStatistics.RoleStat) -> String {
        // Inflection markup is only resolved by AttributedString(localized:), not String(localized:).
        let counts = String(AttributedString(localized: "^[\(stat.deliveries) delivery](inflect: true), ^[\(stat.babies) baby](inflect: true)", bundle: .module).characters)
        return "\(stat.role.displayName): \(counts)"
    }

    private func drawRoleSection(config: Configuration, yPosition: CGFloat) -> CGFloat {
        let stats = DeliveryStatistics.roleBreakdown(deliveries: config.deliveries)
        guard !stats.isEmpty else { return yPosition }
        var y = yPosition
        "My Role".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.black])
        y += 28
        for stat in stats {
            roleLine(stat).draw(at: CGPoint(x: margin + 16, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black])
            y += 18
        }
        return y + 16
    }

    private func drawFooter(yPosition: CGFloat) {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        let text = "Generated by Stork on \(df.string(from: Date()))"
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray]
        text.draw(at: CGPoint(x: (pageWidth - text.size(withAttributes: attrs).width) / 2, y: yPosition), withAttributes: attrs)
    }

    private func dateRangeDescription(config: Configuration) -> String {
        let dates = config.deliveries.map(\.date)
        guard let days = ReportPeriod.days(range: config.dateRange, custom: config.customDateInterval, deliveryDates: dates) else {
            return config.dateRange.displayName
        }
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: days.start, to: days.end)
    }
}

private extension UIColor {
    /// The colour with its brightness reduced, so white text on it stays readable.
    func darkened(by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(hue: h, saturation: s, brightness: b * (1 - amount), alpha: a)
    }
}

private extension UIBezierPath {
    func fill(with color: UIColor) {
        color.setFill()
        fill()
    }
}
#endif
