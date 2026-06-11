//
//  DeliveryMethod+AppEnum.swift
//  Stork
//

import AppIntents

nonisolated extension DeliveryMethod: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Delivery Method"
    }

    static var caseDisplayRepresentations: [DeliveryMethod: DisplayRepresentation] {
        [
            .vaginal: "Vaginal",
            .cSection: "C-Section",
            .vBac: "VBAC"
        ]
    }
}
