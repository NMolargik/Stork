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
        let model = ExportModel(loadDeliveries: loadDeliveries, entitlement: entitlement)
        model.onMilestoneCardShared = { [weak self] in self?.noteMilestoneCardShared() }
        return model
    }
}
#endif
