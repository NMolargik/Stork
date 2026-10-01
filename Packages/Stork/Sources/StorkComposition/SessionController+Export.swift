//
//  SessionController+Export.swift
//  StorkComposition
//
//  View-model factory for Export.
//

#if os(iOS)
import StorkFeatureExport

public extension SessionController {
    func makeExportModel() -> ExportModel {
        ExportModel(loadDeliveries: loadDeliveries)
    }
}
#endif
