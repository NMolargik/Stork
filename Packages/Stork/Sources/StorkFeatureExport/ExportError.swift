//
//  ExportError.swift
//  StorkFeatureExport
//

import Foundation

public enum ExportError: Error, LocalizedError {
    case pdfGenerationFailed(String)
    case csvExportFailed(String)
    case imageRenderingFailed(String)
    case fileCreationFailed(String)
    case noDataToExport
    case invalidDateRange

    public var errorDescription: String? {
        switch self {
        case .pdfGenerationFailed(let detail): "PDF generation failed: \(detail)"
        case .csvExportFailed(let detail): "CSV export failed: \(detail)"
        case .imageRenderingFailed(let detail): "Image rendering failed: \(detail)"
        case .fileCreationFailed(let detail): "File creation failed: \(detail)"
        case .noDataToExport: "No deliveries found for the selected date range."
        case .invalidDateRange: "The selected date range is invalid."
        }
    }
}
