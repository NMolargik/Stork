//
//  StorkTests.swift
//  StorkTests
//
//  App-target tests. The bulk of the suite now lives in the Swift package
//  (`Packages/Stork` — run `swift test`): domain, repositories, and services are tested
//  there, simulator-free. This target covers only app-target glue.
//

import Testing
@testable import Stork

@Suite("App Glue Tests")
struct AppGlueTests {

    @Test("DeliveryMethod app-enum mirrors the core raw values")
    func appEnumRawValues() {
        #expect(DeliveryMethodAppEnum.vaginal.rawValue == "vaginal")
        #expect(DeliveryMethodAppEnum.cSection.rawValue == "cSection")
        #expect(DeliveryMethodAppEnum.vBac.rawValue == "vBac")
        #expect(DeliveryMethodAppEnum(rawValue: "vBac") == .vBac)
    }
}
