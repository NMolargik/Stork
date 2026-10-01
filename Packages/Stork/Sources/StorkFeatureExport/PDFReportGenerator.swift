//
//  PDFReportGenerator.swift
//  StorkFeatureExport
//
//  Renders a US-Letter PDF summary (totals, method breakdown, sex distribution).
//

#if os(iOS)
import Foundation
import UIKit
import StorkCore

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
            _ = drawSexDistributionSection(config: configuration, yPosition: y); progressCallback?(0.8)
            drawFooter(yPosition: pageHeight - margin); progressCallback?(1.0)
        }
    }

    private func drawHeader(config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition
        "Delivery Report".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.black])
        y += 36
        dateRangeDescription(config: config).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.darkGray])
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
        let stats = [("Total Deliveries", "\(totalDeliveries)"), ("Total Babies", "\(totalBabies)"), ("Epidural Usage", String(format: "%.1f%%", epiduralPercent))]
        let statWidth = contentWidth / CGFloat(stats.count)
        for (index, stat) in stats.enumerated() {
            drawStatBox(label: stat.0, value: stat.1, at: CGPoint(x: margin + CGFloat(index) * statWidth, y: y), width: statWidth - 10)
        }
        return y + 70
    }

    private func drawStatBox(label: String, value: String, at point: CGPoint, width: CGFloat) {
        let path = UIBezierPath(roundedRect: CGRect(x: point.x, y: point.y, width: width, height: 50), cornerRadius: 8)
        UIColor.systemGray.setFill()
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
            ("Vaginal", deliveries.count { $0.deliveryMethod == .vaginal }, UIColor.systemBlue),
            ("C-Section", deliveries.count { $0.deliveryMethod == .cSection }, UIColor.systemOrange),
            ("VBAC", deliveries.count { $0.deliveryMethod == .vBac }, UIColor.systemPurple),
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
            ("Boys", allBabies.count { $0.sex == .male }, UIColor.systemBlue),
            ("Girls", allBabies.count { $0.sex == .female }, UIColor.systemPink),
            ("Loss", allBabies.count { $0.sex == .loss }, UIColor.systemPurple),
        ]
        for (name, count, color) in sexes {
            let percent = Double(count) / Double(total) * 100
            UIBezierPath(ovalIn: CGRect(x: margin, y: y + 2, width: 10, height: 10)).fill(with: color)
            "\(name): \(count) (\(String(format: "%.1f", percent))%)".draw(at: CGPoint(x: margin + 16, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black])
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
        if config.dateRange == .custom, let interval = config.customDateInterval {
            let df = DateFormatter()
            df.dateStyle = .medium
            return "\(df.string(from: interval.start)) – \(df.string(from: interval.end))"
        }
        return config.dateRange.displayName
    }
}

private extension UIBezierPath {
    func fill(with color: UIColor) {
        color.setFill()
        fill()
    }
}
#endif
