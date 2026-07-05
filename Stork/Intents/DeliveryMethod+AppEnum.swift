//
//  DeliveryMethod+AppEnum.swift
//  Stork
//
//  App Intents can't synthesize `AppEnum` metadata for an enum defined in an imported
//  package, so the intents use this app-target mirror of `StorkCore.DeliveryMethod` and
//  bridge with `.core` / `init(_:)`.
//

import AppIntents
import StorkCore

enum DeliveryMethodAppEnum: String, AppEnum {
    case vaginal
    case cSection
    case vBac

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Delivery Method" }

    static var caseDisplayRepresentations: [DeliveryMethodAppEnum: DisplayRepresentation] {
        [
            .vaginal: "Vaginal",
            .cSection: "C-Section",
            .vBac: "VBAC",
        ]
    }

    init(_ method: DeliveryMethod) {
        self = DeliveryMethodAppEnum(rawValue: method.rawValue) ?? .vaginal
    }

    var core: DeliveryMethod { DeliveryMethod(rawValue: rawValue) ?? .vaginal }
    var displayName: String { core.displayName }
}
