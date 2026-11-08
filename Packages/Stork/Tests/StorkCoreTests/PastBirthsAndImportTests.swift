//
//  PastBirthsAndImportTests.swift
//  StorkCoreTests
//
//  Estimated past births (totals, exclusions), the CSV import preview, the identifier
//  heuristics and the app-lock policy.
//

import Testing
import Foundation
@testable import StorkCore

private let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

private let now = date(2026, 11, 9)

@MainActor
private func logged(_ d: Date, babies: [Sex] = [.female], method: DeliveryMethod = .vaginal, role: BirthRole? = nil) -> Delivery {
    let kids = babies.map { Baby(sex: $0) }
    let delivery = Delivery(date: d, babies: kids, babyCount: kids.count, deliveryMethod: method, epiduralUsed: false, role: role)
    for k in kids { k.delivery = delivery }
    return delivery
}

@Suite("Past births")
@MainActor
struct PastBirthsTests {

    @Test("Defaults add nothing: babies equal births and sex stays unknown")
    func defaults() {
        let c = PastBirths.counts(births: 120, splits: PastBirthsSplits())
        #expect(c == .init(deliveries: 120, babies: 120, boys: 0, girls: 0, losses: 0))
    }

    @Test("Splits scale by percent and the girls are the remainder")
    func splits() {
        let c = PastBirths.counts(births: 200, splits: .init(multiplesPercent: 5, lossesPercent: 2, boysPercent: 50))
        #expect(c.deliveries == 200)
        #expect(c.babies == 210)           // +10 from multiples
        #expect(c.losses == 4)             // 2% of 210, rounded
        #expect(c.boys + c.girls + c.losses == c.babies)
        #expect(c.boys == 103)             // 50% of 206 live
    }

    @Test("A range builds one entry per year")
    func range() {
        let years = PastBirths.years(from: 2015, to: 2019, average: 150)
        #expect(years.map(\.year) == [2015, 2016, 2017, 2018, 2019])
        #expect(years.allSatisfy { $0.births == 150 })
        #expect(PastBirths.years(from: 2020, to: 2019, average: 10).isEmpty)
    }

    @Test("Validation catches bad years, duplicates and counts")
    func validation() {
        let issues = PastBirths.validate(
            [.init(year: 1900, births: 10), .init(year: 2030, births: 10), .init(year: 2020, births: 5), .init(year: 2020, births: 9999)],
            now: now, calendar: cal
        )
        #expect(issues.contains(.yearOutOfRange(1900)))
        #expect(issues.contains(.yearOutOfRange(2030)))
        #expect(issues.contains(.duplicateYear(2020)))
        #expect(issues.contains(.birthsOutOfRange(year: 2020)))
        #expect(PastBirths.validate([], now: now, calendar: cal) == [.noYears])
        #expect(PastBirths.validate([.init(year: 2020, births: 5)], splits: .init(lossesPercent: 150), now: now, calendar: cal) == [.percentOutOfRange])
    }

    @Test("Summaries are flagged estimated, dated mid-year, and skip zero years")
    func records() {
        let made = PastBirths.makeDeliveries(
            years: [.init(year: 2019, births: 100), .init(year: 2020, births: 0), .init(year: 2026, births: 40)],
            role: .midwife, now: now, calendar: cal
        )
        #expect(made.count == 2)
        #expect(made.allSatisfy { $0.isEstimated && $0.role == .midwife && $0.babies?.isEmpty != false })
        #expect(made[0].date == date(2019, 7, 1))
        #expect(made[1].date == date(2026, 7, 1))
        // current year before July 1 clamps to now
        let early = PastBirths.makeDeliveries(years: [.init(year: 2026, births: 3)], now: date(2026, 3, 1), calendar: cal)
        #expect(early[0].date == date(2026, 3, 1))
    }

    @Test("Estimated births count toward career totals, sex split, roles and year over year")
    func countsWhereTheyShould() {
        let estimated = PastBirths.makeDeliveries(
            years: [.init(year: 2019, births: 100)],
            splits: .init(multiplesPercent: 10, boysPercent: 50), role: .primaryNurse, now: now, calendar: cal
        )
        let real = [logged(date(2026, 5, 2), babies: [.male, .female], role: .primaryNurse), logged(date(2026, 5, 3))]
        let all = real + estimated

        let totals = DeliveryStatistics.totals(deliveries: all)
        #expect(totals.deliveries == 102)
        #expect(totals.babies == 113)           // 110 estimated + 3 logged

        let sex = DeliveryStatistics.sexDistribution(deliveries: all)
        #expect(sex.maleCount == 55 + 1)
        #expect(sex.femaleCount == 55 + 2)
        #expect(sex.total == 113)

        let roles = DeliveryStatistics.roleBreakdown(deliveries: all)
        #expect(roles.first?.deliveries == 101)

        let yoy = DeliveryStatistics.yearOverYearStats(deliveries: all, asOf: now, calendar: cal)
        #expect(yoy.yearlyData.first(where: { $0.year == 2019 })?.deliveries == 100)
        #expect(yoy.currentYearDeliveries == 2)
    }

    @Test("Estimated births are excluded from day, hour, month, streak, method and jar stats")
    func excludedWhereMisleading() {
        let estimated = PastBirths.makeDeliveries(years: [.init(year: 2026, births: 400)], now: date(2026, 11, 20), calendar: cal)
        let real = [logged(date(2026, 7, 1, 9))]    // same day as the placeholder
        let all = real + estimated

        #expect(DeliveryStatistics.timeOfDayStats(deliveries: all, calendar: cal).total == 1)
        #expect(DeliveryStatistics.dayOfWeekStats(deliveries: all, calendar: cal).total == 1)
        #expect(DeliveryStatistics.deliveryMethodStats(deliveries: all).total == 1)
        #expect(DeliveryStatistics.personalBests(deliveries: all, calendar: cal).mostDeliveriesInDay?.count == 1)
        #expect(DeliveryStatistics.monthlyBabyCounts(deliveries: all, calendar: cal).counts == [1])
        let jar = DeliveryStatistics.jarMarbles(deliveries: all, asOf: date(2026, 7, 15), calendar: cal)
        #expect(jar.count == 1)
        #expect(DeliveryStatistics.epiduralUsagePercentage(deliveries: all) == 0)
    }

    @Test("The Year Wrap ignores estimated summaries")
    func wrapIgnores() {
        let estimated = PastBirths.makeDeliveries(years: [.init(year: 2025, births: 300)], now: now, calendar: cal)
        #expect(YearWrap.availableYears(deliveries: estimated, calendar: cal).isEmpty)
        #expect(YearWrap.build(deliveries: estimated, year: 2025, calendar: cal) == nil)
    }

    @Test("Filters never match estimated records")
    func filterSkips() {
        let estimated = PastBirths.makeDeliveries(years: [.init(year: 2025, births: 10)], now: now, calendar: cal)[0]
        #expect(DeliveryFilter(epiduralUsedOnly: false, searchText: "vag").matches(estimated) == false)
    }
}

@Suite("CSV import")
@MainActor
struct CSVImportTests {

    private func preview(_ csv: String, existing: [Delivery] = []) -> CSVImportPreview {
        DeliveryCSVImport.preview(csv: csv, existing: existing, now: now, calendar: cal)
    }

    @Test("Parses quoted fields, CRLF and a BOM")
    func tokenizer() {
        let rows = CSVTable.parse("\u{FEFF}date,notes\r\n2024-01-02,\"a, \"\"b\"\"\"\r\n")
        #expect(rows == [["date", "notes"], ["2024-01-02", "a, \"b\""]])
    }

    @Test("A valid file previews every row as ready")
    func valid() {
        let p = preview(DeliveryCSVImport.template)
        #expect(p.rows.count == 2)
        #expect(p.readyCount == 2)
        #expect(p.errorCount == 0)
        #expect(p.rows[1].draft?.sexes == [.male, .female])
        #expect(p.rows[1].draft?.babyCount == 2)
        #expect(p.rows[1].draft?.method == .cSection)
        #expect(p.rows[1].draft?.role == .transitionNurse)
        #expect(p.rows[1].draft?.hasTime == true)
        let made = DeliveryCSVImport.makeDeliveries(from: p)
        #expect(made.count == 2)
        #expect(made[1].babies?.count == 2 && made[1].deliveryMethod == .cSection)
    }

    @Test("Date is required; per-row errors carry the line number")
    func errors() {
        let p = preview("""
        date,sex,babies
        2024-02-30,girl,1
        ,boy,1
        2999-01-01,girl,1
        2024-05-05,alien,1
        2024-05-06,girl,9
        2024-05-07,boy;girl,3
        2024-05-08,girl,1
        """)
        #expect(p.rows.map(\.id) == [2, 3, 4, 5, 6, 7, 8])
        #expect(p.errorCount == 6)
        #expect(p.rows[1].status == .error(.missingDate))
        #expect(p.rows[2].status == .error(.futureDate))
        #expect(p.rows[6].status == .ready)
        #expect(DeliveryCSVImport.makeDeliveries(from: p).count == 1)
        let noDate = preview("sex\nboy")
        #expect(noDate.missingDateColumn)
    }

    @Test("Identifier columns are dropped and reported, and never reach a delivery")
    func dropsIdentifiers() {
        let p = preview("""
        Date,Patient Name,MRN,DOB,Mother's Name,Sex,Phone,Notes
        2024-03-01,Jane Doe,12345678,1990-01-01,Ana Lopez,girl,555-123-4567,easy
        """)
        #expect(Set(p.droppedColumns) == ["Patient Name", "MRN", "DOB", "Mother's Name", "Phone"])
        #expect(p.readyCount == 1)
        #expect(p.rows[0].draft?.notes == "easy")
    }

    @Test("A note that looks like an identifier is dropped with a warning")
    func dropsIdentifyingNotes() {
        let p = preview("date,notes\n2024-03-01,Name: Jane Doe\n2024-03-02,MRN 99887766")
        #expect(p.rows.allSatisfy { $0.draft?.notes == nil && $0.warnings.contains(.notesDropped) })
        #expect(p.readyCount == 2)
    }

    @Test("Date of birth never stands in for the delivery date")
    func dobIsNotDate() {
        let p = preview("Date of Birth,Sex\n2024-03-01,girl")
        #expect(p.droppedColumns == ["Date of Birth"])
        #expect(p.missingDateColumn)
    }

    @Test("Existing deliveries are detected as duplicates, counting multiplicity")
    func duplicatesAgainstExisting() {
        let existing = [logged(date(2024, 3, 14, 8), babies: [.female], method: .vaginal)]
        let p = preview("""
        date,sex,method
        2024-03-14,girl,vaginal
        2024-03-14,girl,vaginal
        2024-03-14,boy,vaginal
        2024-03-15,girl,vaginal
        """, existing: existing)
        #expect(p.rows[0].status == .duplicate)      // matches the one existing delivery
        #expect(p.rows[1].status == .ready)          // a genuine second delivery that day
        #expect(p.rows[2].status == .ready)          // different sex
        #expect(p.rows[3].status == .ready)          // different day
        #expect(p.duplicateCount == 1)
        #expect(DeliveryCSVImport.makeDeliveries(from: p).count == 3)
        #expect(DeliveryCSVImport.makeDeliveries(from: p, includeDuplicates: true).count == 4)
    }

    @Test("Identical rows within one file are flagged after the first")
    func duplicatesInFile() {
        let p = preview("date,sex\n2024-03-14,girl\n2024-03-14,girl\n2024-03-14,girl")
        #expect(p.rows.map(\.status) == [.ready, .duplicate, .duplicate])
    }

    @Test("Estimated summaries never count as duplicates")
    func estimatedNotDuplicate() {
        let estimated = PastBirths.makeDeliveries(years: [.init(year: 2024, births: 5)], now: now, calendar: cal)
        let p = preview("date\n2024-07-01", existing: estimated)
        #expect(p.readyCount == 1)
    }

    @Test("Rows without a sex keep the baby count but create no Baby rows")
    func noSex() {
        let p = preview("date,babies\n2024-03-14,2")
        #expect(p.rows[0].warnings.contains(.noSex))
        let made = DeliveryCSVImport.makeDeliveries(from: p)
        #expect(made[0].babyCount == 2)
        #expect(made[0].babies?.isEmpty != false)
    }

    @Test("Date formats: ISO, US and spelled out")
    func dateFormats() {
        for raw in ["2024-03-14", "3/14/2024", "03/14/2024", "Mar 14, 2024", "14 March 2024", "2024-03-14 22:30", "2024-03-14T22:30:00Z", "25/03/2024"] {
            #expect(DeliveryCSVImport.parseDate(raw, calendar: cal) != nil, "\(raw)")
        }
        #expect(DeliveryCSVImport.parseDate("not a date", calendar: cal) == nil)
    }

    @Test("Empty file")
    func empty() {
        #expect(preview("").isEmptyFile)
    }
}

@Suite("Identifier heuristics")
struct IdentifierHeuristicsTests {

    @Test("Flags the identifier shapes", arguments: [
        ("MRN 4455667 came in fast", IdentifierKind.medicalRecordNumber),
        ("medical record number: 99881234", .medicalRecordNumber),
        ("Pt ID 7765432", .medicalRecordNumber),
        ("DOB 3/14/1992", .dateOfBirth),
        ("mom born March 14, 1992", .dateOfBirth),
        ("1992-03-14", .dateOfBirth),
        ("Name: Jane", .nameField),
        ("Patient: Smith", .nameField),
        ("Mom: Ana", .nameField),
        ("Went fast for Jessica Alvarez", .personName),
        ("call 555-123-4567", .contactDetail),
    ])
    func flags(_ text: String, _ kind: IdentifierKind) {
        #expect(IdentifierHeuristics.detect(in: text).contains(kind), "\(text)")
    }

    @Test("Leaves ordinary shift notes alone", arguments: [
        "Fast labor, great teamwork",
        "Twins on Christmas Eve",
        "Emergency Cesarean at night",
        "Skin to skin right away. Delayed cord clamping.",
        "Busy Friday night shift, three births",
        "Labor Day weekend",
        "",
    ])
    func clean(_ text: String) {
        #expect(IdentifierHeuristics.detect(in: text).isEmpty, "\(text)")
    }

    @Test("Header detection")
    func headers() {
        for h in ["Name", "patient_name", "MRN", "Medical Record Number", "DOB", "Date of Birth", "Phone", "email", "Address", "SSN", "Mother"] {
            #expect(IdentifierHeuristics.isIdentifierHeader(h), "\(h)")
        }
        for h in ["date", "sex", "babies", "role", "method", "notes"] {
            #expect(!IdentifierHeuristics.isIdentifierHeader(h), "\(h)")
        }
    }
}

@Suite("App lock policy")
struct AppLockPolicyTests {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    @Test("Never locks when disabled")
    func disabled() {
        #expect(!AppLockPolicy.shouldLock(isEnabled: false, backgroundedAt: nil, now: t0, timeout: 0))
    }

    @Test("Locks on a fresh launch")
    func launch() {
        #expect(AppLockPolicy.shouldLock(isEnabled: true, backgroundedAt: nil, now: t0, timeout: 900))
    }

    @Test("Locks only once the grace period has passed")
    func grace() {
        #expect(!AppLockPolicy.shouldLock(isEnabled: true, backgroundedAt: t0, now: t0.addingTimeInterval(59), timeout: 60))
        #expect(AppLockPolicy.shouldLock(isEnabled: true, backgroundedAt: t0, now: t0.addingTimeInterval(60), timeout: 60))
        #expect(AppLockPolicy.shouldLock(isEnabled: true, backgroundedAt: t0, now: t0, timeout: 0))
    }

    @Test("Unknown stored timeouts fall back to the default")
    func normalize() {
        #expect(AppLockPolicy.normalizedTimeout(300) == 300)
        #expect(AppLockPolicy.normalizedTimeout(7) == AppLockPolicy.defaultTimeout)
        #expect(AppLockPolicy.normalizedTimeout(nil) == AppLockPolicy.defaultTimeout)
    }
}
