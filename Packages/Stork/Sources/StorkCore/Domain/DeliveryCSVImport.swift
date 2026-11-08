//
//  DeliveryCSVImport.swift
//  StorkCore
//
//  Parses a CSV of individual births into a reviewable preview: per-row status (ready,
//  duplicate, error), warnings, and the columns that were dropped because they look like
//  patient identifiers. Never imports names or identifiers: any column whose header looks
//  like one is discarded, and a note that looks like one is dropped from its row.
//  Pure and deterministic (injectable `Calendar` / `Date`); no I/O.
//
//  Columns (header names are case-insensitive, spaces/underscores interchangeable):
//    date (required)         2026-03-14, 2026-03-14 22:30, 3/14/2026, Mar 14 2026
//    sex                     boy|girl|loss (also male/female/m/f); several for multiples: "boy;girl"
//    babies                  1 to 6; defaults to the number of sexes listed, else 1
//    role                    primary nurse, transition, charge, preceptor, student, midwife, doula, resident, other
//    method                  vaginal | cesarean (c-section) | vbac; defaults to vaginal
//    notes                   free text (dropped if it looks like a patient identifier)
//

import Foundation

// MARK: - CSV tokenizer

nonisolated public enum CSVTable {
    /// RFC 4180-style parsing: quoted fields, doubled quotes, CRLF or LF, optional BOM,
    /// comma / semicolon / tab delimiter sniffed from the header line.
    public static func parse(_ text: String) -> [[String]] {
        var input = text
        if input.hasPrefix("\u{FEFF}") { input.removeFirst() }
        let delimiter = sniffDelimiter(input)
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var iterator = input.makeIterator()
        var pending: Character? = nil

        func endField() { row.append(field); field = "" }
        func endRow() {
            endField()
            if !(row.count == 1 && row[0].trimmingCharacters(in: .whitespaces).isEmpty) { rows.append(row) }
            row = []
        }

        while let c = pending ?? iterator.next() {
            pending = nil
            if inQuotes {
                if c == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" { field.append("\"") } else { inQuotes = false; pending = next }
                    } else { inQuotes = false }
                } else {
                    field.append(c)
                }
            } else if c == "\"" && field.isEmpty {
                inQuotes = true
            } else if c == delimiter {
                endField()
            } else if c == "\r\n" || c == "\n" || c == "\r" {
                endRow()
            } else {
                field.append(c)
            }
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }

    private static func sniffDelimiter(_ text: String) -> Character {
        let firstLine = text.prefix { $0 != "\n" && $0 != "\r" && $0 != "\r\n" }
        let counts: [(Character, Int)] = [",", ";", "\t"].map { d in (d, firstLine.filter { $0 == d }.count) }
        return counts.max { $0.1 < $1.1 }.flatMap { $0.1 > 0 ? $0.0 : nil } ?? ","
    }
}

// MARK: - Preview types

nonisolated public struct ImportedDeliveryDraft: Equatable, Sendable {
    public var date: Date
    public var hasTime: Bool
    public var sexes: [Sex]          // empty = sex not given
    public var babyCount: Int
    public var method: DeliveryMethod?
    public var role: BirthRole?
    public var notes: String?

    /// A short description for the preview list. Deliberately leaves notes out.
    public func summary(calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateFormat = hasTime ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
        var parts = [f.string(from: date)]
        if sexes.isEmpty {
            parts.append(String(localized: "^[\(babyCount) baby](inflect: true)", bundle: .module))
        } else {
            parts.append(sexes.map(\.displayName).joined(separator: " + "))
        }
        if let method, method != .vaginal { parts.append(method.displayName) }
        return parts.joined(separator: " \u{00B7} ")
    }
}

/// Why a row cannot be imported.
nonisolated public enum CSVRowError: Equatable, Sendable {
    case missingDate
    case unreadableDate(String)
    case futureDate
    case tooOld
    case unrecognizedSex(String)
    case babyCountOutOfRange
    case babyCountMismatch(count: Int, sexes: Int)
    case tooManyRows(Int)

    public var message: String {
        switch self {
        case .missingDate: String(localized: "Missing date.", bundle: .module)
        case .unreadableDate(let raw): String(localized: "Could not read the date \"\(raw)\". Use YYYY-MM-DD.", bundle: .module)
        case .futureDate: String(localized: "The date is in the future.", bundle: .module)
        case .tooOld: String(localized: "The date is before \(DeliveryCSVImport.earliestYear).", bundle: .module)
        case .unrecognizedSex(let raw): String(localized: "Unrecognized sex \"\(raw)\". Use boy, girl or loss.", bundle: .module)
        case .babyCountOutOfRange: String(localized: "Babies must be a number from 1 to 6.", bundle: .module)
        case .babyCountMismatch(let count, let sexes): String(localized: "Babies is \(count) but \(sexes) sexes are listed.", bundle: .module)
        case .tooManyRows(let limit): String(localized: "Too many rows. Import is limited to \(limit) rows at a time.", bundle: .module)
        }
    }
}

/// A row that imports, with something worth mentioning.
nonisolated public enum CSVRowWarning: Equatable, Sendable {
    case roleNotRecognized(String)
    case methodNotRecognized(String)
    case notesDropped
    case noSex
    case repeatedInFile

    public var message: String {
        switch self {
        case .roleNotRecognized(let raw): String(localized: "Role \"\(raw)\" not recognized; left blank.", bundle: .module)
        case .methodNotRecognized(let raw): String(localized: "Method \"\(raw)\" not recognized; counted as vaginal.", bundle: .module)
        case .notesDropped: String(localized: "Notes dropped: they looked like a name, date of birth or record number.", bundle: .module)
        case .noSex: String(localized: "No sex given; babies are counted but not in the boy/girl split.", bundle: .module)
        case .repeatedInFile: String(localized: "Same as an earlier row in this file.", bundle: .module)
        }
    }
}

nonisolated public struct CSVImportRow: Identifiable, Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case ready
        case duplicate
        case error(CSVRowError)
    }

    public let id: Int                  // 1-based line number in the file (header is line 1)
    public var status: Status
    public var draft: ImportedDeliveryDraft?
    public var warnings: [CSVRowWarning]
}

nonisolated public struct CSVImportPreview: Equatable, Sendable {
    public var rows: [CSVImportRow]
    /// Header names of columns that look like patient identifiers and were discarded.
    public var droppedColumns: [String]
    /// Headers that were not recognized and not identifiers (ignored).
    public var ignoredColumns: [String]
    public var missingDateColumn: Bool
    public var isEmptyFile: Bool

    public var readyCount: Int { rows.count { $0.status == .ready } }
    public var duplicateCount: Int { rows.count { $0.status == .duplicate } }
    public var errorCount: Int { rows.count { if case .error = $0.status { true } else { false } } }
}

// MARK: - Importer

nonisolated public enum DeliveryCSVImport {

    public static let maxRows = 20_000
    public static let earliestYear = 1950

    /// The downloadable template (header + two example rows).
    public static let template = """
    date,sex,babies,role,method,notes
    2024-03-14,girl,1,primary nurse,vaginal,
    2024-03-15 22:30,boy;girl,2,transition,cesarean,Twins
    """

    static func templateHeaders() -> [String] { ["date", "sex", "babies", "role", "method", "notes"] }

    private enum Field { case date, sex, babies, role, method, notes }

    private static func field(for header: String) -> Field? {
        switch IdentifierHeuristics.normalizedHeader(header) {
        case "date", "delivery date", "date delivered", "delivered", "deliverydate": .date
        case "sex", "gender", "baby sex", "sexes": .sex
        case "babies", "baby count", "number of babies", "multiples", "count", "num babies": .babies
        case "role", "my role", "birth role": .role
        case "method", "delivery method", "delivery type", "type", "mode": .method
        case "notes", "note", "comments", "comment": .notes
        default: nil
        }
    }

    /// Parses `text` and checks each row against `existing` deliveries for duplicates.
    @MainActor
    public static func preview(
        csv text: String,
        existing: [Delivery] = [],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> CSVImportPreview {
        let table = CSVTable.parse(text)
        guard let header = table.first else {
            return CSVImportPreview(rows: [], droppedColumns: [], ignoredColumns: [], missingDateColumn: false, isEmptyFile: true)
        }

        var columns: [Field: Int] = [:]
        var dropped: [String] = []
        var ignored: [String] = []
        for (index, raw) in header.enumerated() {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty { continue }
            // Identifier-looking headers win over everything, even if a recognized alias
            // is also present ("Date of Birth" is a DOB, not the delivery date).
            if IdentifierHeuristics.isIdentifierHeader(name) {
                dropped.append(name)
            } else if let f = field(for: name), columns[f] == nil {
                columns[f] = index
            } else {
                ignored.append(name)
            }
        }

        guard let dateColumn = columns[.date] else {
            return CSVImportPreview(rows: [], droppedColumns: dropped, ignoredColumns: ignored, missingDateColumn: true, isEmptyFile: false)
        }

        // Existing deliveries bucketed for duplicate matching (multiset counting, so a
        // genuine second delivery the same day is not wrongly dropped).
        var existingKeys: [String: Int] = [:]
        for delivery in existing where !delivery.isEstimated {
            let sexes = (delivery.babies ?? []).map(\.sex)
            for key in matchKeys(date: delivery.date, babyCount: delivery.babyCount, sexes: sexes, method: delivery.deliveryMethod, calendar: calendar) {
                existingKeys[key, default: 0] += 1
            }
        }

        var rows: [CSVImportRow] = []
        var seenInFile: [String: Int] = [:]

        for (offset, cells) in table.dropFirst().enumerated() {
            if offset >= maxRows {
                rows.append(CSVImportRow(id: offset + 2, status: .error(.tooManyRows(maxRows)), draft: nil, warnings: []))
                break
            }
            let line = offset + 2
            func cell(_ f: Field) -> String? {
                guard let i = columns[f], i < cells.count else { return nil }
                let v = cells[i].trimmingCharacters(in: .whitespacesAndNewlines)
                return v.isEmpty ? nil : v
            }

            var warnings: [CSVRowWarning] = []

            // Date (required)
            guard let rawDate = cell(.date) else {
                rows.append(CSVImportRow(id: line, status: .error(.missingDate), draft: nil, warnings: []))
                continue
            }
            guard let parsed = parseDate(rawDate, calendar: calendar) else {
                rows.append(CSVImportRow(id: line, status: .error(.unreadableDate(String(rawDate.prefix(30)))), draft: nil, warnings: []))
                continue
            }
            guard parsed.date <= now else {
                rows.append(CSVImportRow(id: line, status: .error(.futureDate), draft: nil, warnings: []))
                continue
            }
            guard calendar.component(.year, from: parsed.date) >= earliestYear else {
                rows.append(CSVImportRow(id: line, status: .error(.tooOld), draft: nil, warnings: []))
                continue
            }

            // Sex(es)
            var sexes: [Sex] = []
            if let rawSex = cell(.sex) {
                let parts = rawSex.split(whereSeparator: { ";/|&+,".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }
                for part in parts where !part.isEmpty {
                    if let sex = parseSex(part) { sexes.append(sex) } else {
                        rows.append(CSVImportRow(id: line, status: .error(.unrecognizedSex(String(part.prefix(20)))), draft: nil, warnings: []))
                        sexes = []
                        break
                    }
                }
                if rows.last?.id == line { continue }
            }

            // Babies
            var babyCount = max(1, sexes.count)
            if let rawCount = cell(.babies) {
                guard let n = Int(rawCount), (1...6).contains(n) else {
                    rows.append(CSVImportRow(id: line, status: .error(.babyCountOutOfRange), draft: nil, warnings: []))
                    continue
                }
                if !sexes.isEmpty && sexes.count != n {
                    rows.append(CSVImportRow(id: line, status: .error(.babyCountMismatch(count: n, sexes: sexes.count)), draft: nil, warnings: []))
                    continue
                }
                babyCount = n
            }

            // Role
            var role: BirthRole?
            if let rawRole = cell(.role) {
                if let r = parseRole(rawRole) { role = r } else { warnings.append(.roleNotRecognized(String(rawRole.prefix(20)))) }
            }

            // Method
            var method: DeliveryMethod?
            if let rawMethod = cell(.method) {
                if let m = parseMethod(rawMethod) { method = m } else { warnings.append(.methodNotRecognized(String(rawMethod.prefix(20)))) }
            }

            // Notes: never keep anything that looks like an identifier.
            var notes = cell(.notes)
            if let n = notes, IdentifierHeuristics.looksIdentifying(n) {
                notes = nil
                warnings.append(.notesDropped)
            }

            if sexes.isEmpty { warnings.append(.noSex) }

            let draft = ImportedDeliveryDraft(date: parsed.date, hasTime: parsed.hasTime, sexes: sexes, babyCount: babyCount, method: method, role: role, notes: notes)
            let keys = matchKeys(date: draft.date, hasTime: draft.hasTime, babyCount: babyCount, sexes: sexes, method: method, calendar: calendar)
            let primaryKey = keys[0]

            // Duplicate of an existing delivery?
            var status: CSVImportRow.Status = .ready
            if let matched = keys.first(where: { existingKeys[$0, default: 0] > 0 }) {
                existingKeys[matched, default: 0] -= 1
                status = .duplicate
            } else {
                // Identical earlier row in this same file?
                let fileKey = primaryKey + "|" + (role?.rawValue ?? "") + "|" + (notes ?? "")
                seenInFile[fileKey, default: 0] += 1
                if seenInFile[fileKey]! > 1 { status = .duplicate; warnings.append(.repeatedInFile) }
            }

            rows.append(CSVImportRow(id: line, status: status, draft: draft, warnings: warnings))
        }

        return CSVImportPreview(rows: rows, droppedColumns: dropped, ignoredColumns: ignored, missingDateColumn: false, isEmptyFile: false)
    }

    /// Builds the deliveries for rows to import (ready rows, plus duplicates when asked).
    @MainActor
    public static func makeDeliveries(from preview: CSVImportPreview, includeDuplicates: Bool = false) -> [Delivery] {
        preview.rows.compactMap { row in
            guard let draft = row.draft else { return nil }
            switch row.status {
            case .error: return nil
            case .duplicate where !includeDuplicates: return nil
            default: break
            }
            let delivery = Delivery(
                date: draft.date,
                babyCount: draft.babyCount,
                deliveryMethod: draft.method ?? .vaginal,
                epiduralUsed: false,
                notes: draft.notes,
                role: draft.role
            )
            // Babies are created only when a sex is known; otherwise the delivery keeps
            // just `babyCount` (counted in totals, absent from the sex split).
            if !draft.sexes.isEmpty {
                let babies = draft.sexes.map { Baby(birthday: draft.date, sex: $0, delivery: delivery) }
                delivery.babies = babies
            }
            return delivery
        }
    }

    // MARK: - Duplicate keys

    /// Keys a delivery can match on, most specific first. A date-only row matches by
    /// calendar day; a row with a time also matches by exact minute.
    private static func matchKeys(
        date: Date, hasTime: Bool = true, babyCount: Int, sexes: [Sex], method: DeliveryMethod?, calendar: Calendar
    ) -> [String] {
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let dayKey = "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
        let minuteKey = "\(Int(date.timeIntervalSince1970 / 60))"
        let sexKey = sexes.map(\.rawValue).sorted().joined(separator: ",")
        let methodKey = method?.rawValue ?? ""
        let base = "\(babyCount)|\(sexKey)|\(methodKey)"
        var keys = [hasTime ? "m:\(minuteKey)|\(base)" : "d:\(dayKey)|\(base)"]
        if hasTime { keys.append("d:\(dayKey)|\(base)") }
        return keys
    }

    /// Overload used for existing deliveries: they always carry a time, and a CSV row
    /// that omitted the method / sex should still match on day + count.
    private static func matchKeys(date: Date, babyCount: Int, sexes: [Sex], method: DeliveryMethod, calendar: Calendar) -> [String] {
        var keys: [String] = []
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let dayKey = "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
        let minuteKey = "\(Int(date.timeIntervalSince1970 / 60))"
        let sexOptions = [sexes.map(\.rawValue).sorted().joined(separator: ","), ""]
        let methodOptions = [method.rawValue, ""]
        for s in sexOptions {
            for m in methodOptions {
                keys.append("m:\(minuteKey)|\(babyCount)|\(s)|\(m)")
                keys.append("d:\(dayKey)|\(babyCount)|\(s)|\(m)")
            }
        }
        return keys
    }

    // MARK: - Cell parsing

    private static func parseSex(_ s: String) -> Sex? {
        switch s.lowercased() {
        case "boy", "male", "m", "b": .male
        case "girl", "female", "f", "g": .female
        case "loss", "stillborn", "stillbirth", "fetal loss", "demise", "iufd", "l": .loss
        default: nil
        }
    }

    private static func parseRole(_ s: String) -> BirthRole? {
        let n = s.lowercased().replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
        for role in BirthRole.allCases {
            if role.rawValue.lowercased() == n.replacingOccurrences(of: " ", with: "") { return role }
            if role.displayName.lowercased() == n || role.shortName.lowercased() == n { return role }
        }
        switch n {
        case "primary", "primary nurse", "rn", "labor nurse": return .primaryNurse
        case "transition", "baby nurse", "nursery", "transition nurse": return .transitionNurse
        case "charge": return .chargeNurse
        case "midwife", "cnm": return .midwife
        case "doula": return .doula
        case "student", "nursing student": return .student
        case "resident": return .resident
        default: return nil
        }
    }

    private static func parseMethod(_ s: String) -> DeliveryMethod? {
        let n = s.lowercased().replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        switch n {
        case "vaginal", "vag", "svd", "nsvd", "spontaneous": return .vaginal
        case "csection", "cesarean", "caesarean", "cs", "c/s", "section": return .cSection
        case "vbac", "tolac": return .vBac
        default: return nil
        }
    }

    /// Parses ISO, US (M/d/yyyy) and spelled-out dates, with an optional time.
    static func parseDate(_ raw: String, calendar: Calendar) -> (date: Date, hasTime: Bool)? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        // ISO 8601 with zone
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if s.contains("T"), let d = iso.date(from: s) { return (d, true) }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if s.contains("T"), let d = iso.date(from: s) { return (d, true) }

        let formats: [(String, Bool)] = [
            ("yyyy-MM-dd'T'HH:mm:ss", true), ("yyyy-MM-dd'T'HH:mm", true),
            ("yyyy-MM-dd HH:mm:ss", true), ("yyyy-MM-dd HH:mm", true), ("yyyy-MM-dd", false),
            ("yyyy/MM/dd HH:mm", true), ("yyyy/MM/dd", false),
            ("M/d/yyyy H:mm", true), ("M/d/yyyy h:mm a", true), ("M/d/yyyy", false),
            ("M/d/yy", false), ("M-d-yyyy", false),
            ("MMM d, yyyy h:mm a", true), ("MMM d, yyyy", false), ("MMMM d, yyyy", false),
            ("MMM d yyyy", false), ("MMMM d yyyy", false), ("d MMM yyyy", false), ("d MMMM yyyy", false),
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.isLenient = false
        for (format, hasTime) in formats {
            formatter.dateFormat = format
            guard let date = formatter.date(from: s) else { continue }
            // Two-digit years: DateFormatter maps 'yy' to a window; keep it as given.
            if hasTime { return (date, true) }
            // Date-only: place at noon so time-zone shifts never move the day.
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            return (noon, false)
        }
        // d/M/yyyy when the first number cannot be a month (e.g. 25/03/2026)
        let parts = s.split(separator: "/")
        if parts.count == 3, let a = Int(parts[0]), let b = Int(parts[1]), let y = Int(parts[2]), a > 12, (1...12).contains(b), y > 1000 {
            if let d = calendar.date(from: DateComponents(year: y, month: b, day: a, hour: 12)) { return (d, false) }
        }
        return nil
    }
}
