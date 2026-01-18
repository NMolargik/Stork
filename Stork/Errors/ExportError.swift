//
//  ExportError.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation

enum ExportError: Error, LocalizedError {
    case pdfGenerationFailed(String)
    case csvExportFailed(String)
    case imageRenderingFailed(String)
    case fileCreationFailed(String)
    case noDataToExport
    case invalidDateRange

    var message: String {
        switch self {
        case .pdfGenerationFailed(let detail):
            return "PDF generation failed: \(detail)"
        case .csvExportFailed(let detail):
            return "CSV export failed: \(detail)"
        case .imageRenderingFailed(let detail):
            return "Image rendering failed: \(detail)"
        case .fileCreationFailed(let detail):
            return "File creation failed: \(detail)"
        case .noDataToExport:
            return "No deliveries found for the selected date range."
        case .invalidDateRange:
            return "The selected date range is invalid."
        }
    }

    var errorDescription: String? { message }
}
