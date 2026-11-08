//
//  IdentifierHeuristics.swift
//  StorkCore
//
//  Simple on-device checks for text that looks like it identifies a patient: a medical
//  record number, a date of birth, a "Name:" style field, or a capitalized first + last
//  name pair. Used to show a gentle warning before a note is saved and to drop such
//  notes from CSV imports. Heuristics only: they will miss things and occasionally
//  flag harmless text, which is why the warning never blocks saving. Nothing leaves the
//  device; there is no network or model involved.
//

import Foundation

nonisolated public enum IdentifierKind: String, CaseIterable, Sendable, Hashable {
    case medicalRecordNumber
    case dateOfBirth
    case nameField
    case personName
    case contactDetail
}

nonisolated public enum IdentifierHeuristics {

    /// Which kinds of identifier `text` appears to contain (empty = nothing found).
    public static func detect(in text: String) -> [IdentifierKind] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var found: [IdentifierKind] = []
        if matchesMRN(trimmed) { found.append(.medicalRecordNumber) }
        if matchesDOB(trimmed) { found.append(.dateOfBirth) }
        if matchesNameField(trimmed) { found.append(.nameField) }
        if containsNamePair(trimmed) { found.append(.personName) }
        if matchesContact(trimmed) { found.append(.contactDetail) }
        return found
    }

    public static func looksIdentifying(_ text: String) -> Bool { !detect(in: text).isEmpty }

    /// Whether a CSV column header names an identifier column that must never be imported.
    public static func isIdentifierHeader(_ header: String) -> Bool {
        let h = normalizedHeader(header)
        guard !h.isEmpty else { return false }
        let tokens = [
            "name", "patient", "mrn", "medical record", "record number", "dob", "date of birth",
            "birth date", "birthdate", "birthday", "ssn", "social security", "phone", "email",
            "address", "street", "zip", "postal", "insurance", "account", "mother", "mom",
            "father", "parent", "guardian", "baby name", "chart", "fin", "encounter", "visit",
        ]
        for token in tokens {
            if token.count <= 3 {
                if h.split(separator: " ").contains(Substring(token)) { return true }
            } else if h.contains(token) {
                return true
            }
        }
        return false
    }

    static func normalizedHeader(_ header: String) -> String {
        header.lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    // MARK: - Patterns

    private static func matches(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func matchesMRN(_ text: String) -> Bool {
        // "MRN 12345", "MRN: A-998877", "medical record number 4455667", "acct #...", "patient id ..."
        let labeled = #"\b(mrn|med(ical)?\.?\s*rec(ord)?s?\.?(\s*(no|num|number|#))?|patient\s*(id|no|number|#)|pt\s*(id|#)|acct|account\s*(no|number|#)|chart\s*(no|number|#)|fin|encounter\s*(no|number|#))\b\.?\s*[:#=\-]?\s*[A-Za-z]?[A-Za-z0-9\-]{0,3}\d{3,}"#
        if matches(labeled, in: text, options: .caseInsensitive) { return true }
        // A bare "MRN" mention is enough to warn.
        return matches(#"\bMRN\b"#, in: text, options: .caseInsensitive)
    }

    private static func matchesDOB(_ text: String) -> Bool {
        if matches(#"\b(dob|d\.o\.b\.?|date of birth|birth\s?date|born on)\b"#, in: text, options: .caseInsensitive) { return true }
        // Full numeric dates: 3/14/1992, 03-14-92, 1992-03-14, 14.03.1992
        if matches(#"\b\d{1,2}[/\-.]\d{1,2}[/\-.](19|20)?\d{2}\b"#, in: text) { return true }
        if matches(#"\b(19|20)\d{2}[/\-.]\d{1,2}[/\-.]\d{1,2}\b"#, in: text) { return true }
        // Spelled-out: March 14, 1992 / 14 Mar 1992
        let months = "jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|aug(ust)?|sep(t(ember)?)?|oct(ober)?|nov(ember)?|dec(ember)?"
        if matches(#"\b("# + months + #")\.?\s+\d{1,2}(st|nd|rd|th)?,?\s+(19|20)\d{2}\b"#, in: text, options: .caseInsensitive) { return true }
        if matches(#"\b\d{1,2}(st|nd|rd|th)?\s+("# + months + #")\.?,?\s+(19|20)\d{2}\b"#, in: text, options: .caseInsensitive) { return true }
        return false
    }

    private static func matchesNameField(_ text: String) -> Bool {
        // "Name: Jane", "Patient - Smith", "Mom: Ana", "Baby: Olivia"
        matches(#"\b(first\s+name|last\s+name|full\s+name|name|patient|pt|mom|mother|dad|father|baby|infant|client)\s*[:=]\s*\S"#, in: text, options: .caseInsensitive)
            || matches(#"\b(patient|pt)\s+name\b"#, in: text, options: .caseInsensitive)
    }

    private static let notNames: Set<String> = [
        // days and months
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
        "january", "february", "march", "april", "may", "june", "july", "august", "september",
        "october", "november", "december",
        // holidays and common capitalized phrases
        "christmas", "eve", "day", "new", "year", "years", "thanksgiving", "easter", "halloween",
        "labor", "memorial", "independence", "valentine", "valentines", "mothers", "fathers",
        "super", "bowl", "full", "moon",
        // clinical and unit words
        "delivery", "cesarean", "section", "emergency", "induction", "induced", "vaginal", "birth",
        "baby", "babies", "mother", "mom", "dad", "father", "nurse", "nursing", "doctor", "midwife",
        "doula", "resident", "student", "charge", "primary", "transition", "preceptor", "shift",
        "night", "morning", "evening", "afternoon", "weekend", "unit", "floor", "room", "triage",
        "operating", "recovery", "postpartum", "antepartum", "intrapartum", "epidural", "nicu",
        "vbac", "twins", "triplets", "twin", "breech", "preterm", "term", "post", "healthy",
        "great", "good", "long", "short", "fast", "quick", "first", "second", "third", "last",
        "big", "little", "tiny", "busy", "slow", "calm", "very", "really", "so", "no", "yes",
        "the", "and", "with", "went", "was", "came", "had", "great", "well", "smooth",
        "skin", "cord", "clamping", "clamp", "delayed", "golden", "hour", "hours", "care",
        "kangaroo", "labor", "stage", "pushing", "water", "home", "birthing", "center",
    ]

    private static func containsNamePair(_ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: #"(?<![A-Za-z])([A-Z][a-z]{2,})\s+([A-Z][a-z]{2,})(?![A-Za-z])"#) else { return false }
        let ns = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let first = ns.substring(with: match.range(at: 1))
            let second = ns.substring(with: match.range(at: 2))
            if notNames.contains(first.lowercased()) || notNames.contains(second.lowercased()) { continue }
            // "Dr. Smith Jones" style: skip when a title precedes (a clinician, not a patient).
            let prefix = ns.substring(to: match.range.location).trimmingCharacters(in: .whitespaces).lowercased()
            if prefix.hasSuffix("dr.") || prefix.hasSuffix("dr") { continue }
            return true
        }
        return false
    }

    private static func matchesContact(_ text: String) -> Bool {
        matches(#"\b\d{3}-\d{2}-\d{4}\b"#, in: text)                                   // SSN
            || matches(#"\b(\+?1[\s.\-]?)?\(?\d{3}\)?[\s.\-]\d{3}[\s.\-]\d{4}\b"#, in: text)  // phone
            || matches(#"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#, in: text, options: .caseInsensitive) // email
    }
}
