//
//  PastBirthsModelTests.swift
//  StorkFeatureSettingsTests
//
//  Add Past Births and CSV import view models over fake use-cases.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureSettings

@MainActor
private final class Store {
    var deliveries: [Delivery] = []
    var error: PersistenceError?
    var importCalls = 0
    struct Load: LoadDeliveries {
        let s: Store
        func callAsFunction() throws(PersistenceError) -> [Delivery] { s.deliveries }
    }
    struct Import: ImportDeliveries {
        let s: Store
        func callAsFunction(_ d: [Delivery]) throws(PersistenceError) {
            if let e = s.error { throw e }
            s.importCalls += 1
            s.deliveries.append(contentsOf: d)
        }
    }
}

private let fixedNow = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 12))!

@Suite("AddPastBirthsModel")
@MainActor
struct AddPastBirthsModelTests {
    private func make(_ store: Store = Store()) -> (AddPastBirthsModel, Store) {
        (AddPastBirthsModel(importDeliveries: Store.Import(s: store), now: { fixedNow }, calendar: Calendar(identifier: .gregorian)), store)
    }

    @Test("Defaults to the five years before this one and cannot save until a number is entered")
    func defaults() {
        let (m, _) = make()
        #expect(m.rangeStart == 2021 && m.rangeEnd == 2025)
        #expect(!m.canSave)
        m.averagePerYear = 100
        #expect(m.canSave)
        #expect(m.totals == (5, 500, 500))
    }

    @Test("A range saves one estimated summary per year in a single import")
    func rangeSave() {
        let (m, store) = make()
        m.averagePerYear = 150
        m.role = .primaryNurse
        #expect(m.save())
        #expect(store.importCalls == 1)
        #expect(store.deliveries.count == 5)
        #expect(store.deliveries.allSatisfy { $0.isEstimated && $0.estimatedDeliveries == 150 && $0.role == .primaryNurse })
        #expect(m.savedBirths == 750)
    }

    @Test("Year by year skips blank rows and flags duplicate years")
    func yearByYear() {
        let (m, store) = make()
        m.mode = .yearByYear
        m.rows = [.init(year: 2020, births: 80), .init(year: 2021, births: nil), .init(year: 2022, births: 120)]
        #expect(m.years.map(\.year) == [2020, 2022])
        #expect(m.save())
        #expect(store.deliveries.count == 2)

        let (m2, _) = make()
        m2.mode = .yearByYear
        m2.rows = [.init(year: 2020, births: 80), .init(year: 2020, births: 5)]
        #expect(m2.issues.contains(.duplicateYear(2020)))
        #expect(!m2.save())
    }

    @Test("Splits flow into the totals and the records")
    func splits() {
        let (m, store) = make()
        m.averagePerYear = 100
        m.rangeStart = 2025; m.rangeEnd = 2025
        m.multiplesPercent = 10
        m.lossesPercent = 5
        m.boysPercent = 50
        #expect(m.totals == (1, 100, 110))
        m.save()
        let d = store.deliveries[0]
        #expect(d.babyCount == 110)
        #expect(d.estimatedLosses == 6)      // 5% of 110, rounded
        #expect(d.estimatedBoys + d.estimatedGirls + d.estimatedLosses == 110)
    }

    @Test("A reversed range or a future year blocks saving")
    func invalid() {
        let (m, _) = make()
        m.averagePerYear = 10
        m.rangeStart = 2025; m.rangeEnd = 2022
        #expect(!m.canSave)
        m.rangeStart = 2022; m.rangeEnd = 2030
        #expect(!m.canSave)
    }

    @Test("A failed save surfaces the error and reports no saved births")
    func failure() {
        let (m, store) = make()
        store.error = .saveFailed("disk")
        m.averagePerYear = 10
        #expect(!m.save())
        #expect(m.lastError == .saveFailed("disk"))
        #expect(m.savedBirths == nil)
    }
}

@Suite("CSVImportModel")
@MainActor
struct CSVImportModelTests {
    private func make(_ store: Store = Store()) -> (CSVImportModel, Store) {
        (CSVImportModel(loadDeliveries: Store.Load(s: store), importDeliveries: Store.Import(s: store), now: { fixedNow }, calendar: Calendar(identifier: .gregorian)), store)
    }

    @Test("Previews a file and imports only the ready rows")
    func importsReady() {
        let (m, store) = make()
        m.load(csv: "date,sex,patient name\n2024-03-14,girl,Jane Doe\nbad,boy,John\n2024-03-15,boy,Sam", fileName: "x.csv")
        #expect(m.preview?.droppedColumns == ["patient name"])
        #expect(m.preview?.errorCount == 1)
        #expect(m.importableCount == 2)
        #expect(m.performImport())
        #expect(store.importCalls == 1)
        #expect(store.deliveries.count == 2)
        #expect(m.importedCount == 2)
    }

    @Test("Existing deliveries make matching rows duplicates unless included")
    func duplicates() {
        let store = Store()
        let cal = Calendar(identifier: .gregorian)
        let baby = Baby(sex: .female)
        let existing = Delivery(date: cal.date(from: DateComponents(year: 2024, month: 3, day: 14, hour: 9))!, babies: [baby], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false)
        store.deliveries = [existing]
        let (m, _) = make(store)
        m.load(csv: "date,sex\n2024-03-14,girl", fileName: nil)
        #expect(m.preview?.duplicateCount == 1)
        #expect(m.importableCount == 0)
        #expect(!m.performImport())
        m.includeDuplicates = true
        #expect(m.importableCount == 1)
        #expect(m.performImport())
    }

    @Test("A file with no date column reports it and imports nothing")
    func noDate() {
        let (m, store) = make()
        m.load(csv: "sex\ngirl", fileName: nil)
        #expect(m.preview?.missingDateColumn == true)
        #expect(!m.performImport())
        #expect(store.importCalls == 0)
    }

    @Test("The template previews cleanly")
    func template() {
        let (m, _) = make()
        m.load(csv: CSVImportModel.templateCSV, fileName: nil)
        #expect(m.preview?.errorCount == 0 && m.preview?.readyCount == 2)
    }
}
