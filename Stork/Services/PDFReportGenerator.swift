//
//  PDFReportGenerator.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import UIKit
import SwiftUI
import Charts

@MainActor
final class PDFReportGenerator {

    struct Configuration {
        let deliveries: [Delivery]
        let dateRange: ExportDateRange
        let customDateInterval: DateInterval?
        let useMetricUnits: Bool
        let useDayMonthYearDates: Bool
    }

    // Page dimensions (US Letter)
    private let pageWidth: CGFloat = 612
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50

    private var contentWidth: CGFloat { pageWidth - (margin * 2) }

    func generate(configuration: Configuration, progressCallback: ((Double) -> Void)? = nil) async throws -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Header
            yPosition = drawHeader(in: context, config: configuration, yPosition: yPosition)
            progressCallback?(0.2)

            // Summary Stats
            yPosition = drawSummaryStats(in: context, config: configuration, yPosition: yPosition)
            progressCallback?(0.4)

            // Delivery Method Breakdown
            yPosition = drawDeliveryMethodSection(in: context, config: configuration, yPosition: yPosition)
            progressCallback?(0.6)

            // Check if we need a new page
            if yPosition > pageHeight - 250 {
                context.beginPage()
                yPosition = margin
            }

            // Sex Distribution
            yPosition = drawSexDistributionSection(in: context, config: configuration, yPosition: yPosition)
            progressCallback?(0.8)

            // Footer
            drawFooter(in: context, yPosition: pageHeight - margin)
            progressCallback?(1.0)
        }

        return data
    }

    // MARK: - Header

    private func drawHeader(in context: UIGraphicsPDFRendererContext, config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        // Title
        let title = "Delivery Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 36

        // Date Range
        let dateRangeText = dateRangeDescription(config: config)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        dateRangeText.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)

        y += 30

        // Divider line
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: margin, y: y))
        dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.lightGray.setStroke()
        dividerPath.lineWidth = 0.5
        dividerPath.stroke()

        return y + 20
    }

    // MARK: - Summary Stats

    private func drawSummaryStats(in context: UIGraphicsPDFRendererContext, config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitle = "Summary"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        sectionTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttributes)
        y += 28

        let deliveries = config.deliveries
        let totalDeliveries = deliveries.count
        let totalBabies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        let epiduralCount = deliveries.filter { $0.epiduralUsed }.count
        let epiduralPercent = totalDeliveries > 0 ? Double(epiduralCount) / Double(totalDeliveries) * 100 : 0

        let stats = [
            ("Total Deliveries", "\(totalDeliveries)"),
            ("Total Babies", "\(totalBabies)"),
            ("Epidural Usage", String(format: "%.1f%%", epiduralPercent))
        ]

        let statWidth = contentWidth / CGFloat(stats.count)

        for (index, stat) in stats.enumerated() {
            let x = margin + (CGFloat(index) * statWidth)
            drawStatBox(label: stat.0, value: stat.1, at: CGPoint(x: x, y: y), width: statWidth - 10)
        }

        return y + 70
    }

    private func drawStatBox(label: String, value: String, at point: CGPoint, width: CGFloat) {
        let boxRect = CGRect(x: point.x, y: point.y, width: width, height: 50)

        // Background
        let path = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        UIColor.systemGray.setFill()
        path.fill()

        // Value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let valueSize = value.size(withAttributes: valueAttributes)
        value.draw(at: CGPoint(x: point.x + (width - valueSize.width) / 2, y: point.y + 8), withAttributes: valueAttributes)

        // Label
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        let labelSize = label.size(withAttributes: labelAttributes)
        label.draw(at: CGPoint(x: point.x + (width - labelSize.width) / 2, y: point.y + 32), withAttributes: labelAttributes)
    }

    // MARK: - Delivery Method Section

    private func drawDeliveryMethodSection(in context: UIGraphicsPDFRendererContext, config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitle = "Delivery Methods"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        sectionTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttributes)
        y += 28

        let deliveries = config.deliveries
        let total = deliveries.count
        guard total > 0 else { return y }

        let vaginalCount = deliveries.filter { $0.deliveryMethod == .vaginal }.count
        let cSectionCount = deliveries.filter { $0.deliveryMethod == .cSection }.count
        let vbacCount = deliveries.filter { $0.deliveryMethod == .vBac }.count

        let methods = [
            ("Vaginal", vaginalCount, UIColor.systemBlue),
            ("C-Section", cSectionCount, UIColor.systemOrange),
            ("VBAC", vbacCount, UIColor.systemPurple)
        ]

        // Draw bar chart
        let barHeight: CGFloat = 24
        var xOffset: CGFloat = margin

        for (_, count, color) in methods {
            let percent = Double(count) / Double(total)
            let barWidth = contentWidth * CGFloat(percent)

            let barRect = CGRect(x: xOffset, y: y, width: max(barWidth, 0), height: barHeight)
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 4)
            color.setFill()
            barPath.fill()

            xOffset += barWidth
        }
        y += barHeight + 16

        // Legend
        for (name, count, color) in methods {
            let percent = Double(count) / Double(total) * 100

            // Color dot
            let dotRect = CGRect(x: margin, y: y + 2, width: 10, height: 10)
            let dotPath = UIBezierPath(ovalIn: dotRect)
            color.setFill()
            dotPath.fill()

            // Text
            let text = "\(name): \(count) (\(String(format: "%.1f", percent))%)"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: margin + 16, y: y), withAttributes: textAttributes)

            y += 18
        }

        return y + 16
    }

    // MARK: - Sex Distribution Section

    private func drawSexDistributionSection(in context: UIGraphicsPDFRendererContext, config: Configuration, yPosition: CGFloat) -> CGFloat {
        var y = yPosition

        let sectionTitle = "Baby Sex Distribution"
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        sectionTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttributes)
        y += 28

        let allBabies = config.deliveries.flatMap { $0.babies ?? [] }
        let total = allBabies.count
        guard total > 0 else { return y }

        let maleCount = allBabies.filter { $0.sex == .male }.count
        let femaleCount = allBabies.filter { $0.sex == .female }.count
        let lossCount = allBabies.filter { $0.sex == .loss }.count

        let sexes = [
            ("Boys", maleCount, UIColor.systemBlue),
            ("Girls", femaleCount, UIColor.systemPink),
            ("Loss", lossCount, UIColor.systemPurple)
        ]

        // Simple text display (pie chart would require more complex rendering)
        for (name, count, color) in sexes {
            let percent = Double(count) / Double(total) * 100

            // Color dot
            let dotRect = CGRect(x: margin, y: y + 2, width: 10, height: 10)
            let dotPath = UIBezierPath(ovalIn: dotRect)
            color.setFill()
            dotPath.fill()

            // Text
            let text = "\(name): \(count) (\(String(format: "%.1f", percent))%)"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: margin + 16, y: y), withAttributes: textAttributes)

            y += 18
        }

        return y + 16
    }

    // MARK: - Footer

    private func drawFooter(in context: UIGraphicsPDFRendererContext, yPosition: CGFloat) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        let footerText = "Generated by Stork on \(dateFormatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.gray
        ]

        let footerSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yPosition), withAttributes: footerAttributes)
    }

    // MARK: - Helpers

    private func dateRangeDescription(config: Configuration) -> String {
        if config.dateRange == .custom, let interval = config.customDateInterval {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: interval.start)) – \(formatter.string(from: interval.end))"
        }
        return config.dateRange.displayName
    }
}
