//
//  SessionController+Settings.swift
//  StorkComposition
//
//  View-model factory for Settings.
//

import StorkFeatureSettings

public extension SessionController {
    func makeSettingsModel() -> SettingsModel {
        SettingsModel(
            loadDeliveries: loadDeliveries,
            deleteAllDeliveries: deleteAllDeliveries,
            logDelivery: logDelivery
        )
    }
}
