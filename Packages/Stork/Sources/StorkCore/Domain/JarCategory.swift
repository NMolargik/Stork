//
//  JarCategory.swift
//  StorkCore
//
//  Categorizes each baby as one jar marble. Pure value types; colors live in the
//  design system. Remembrance (loss) is deliberately its own category: it is never
//  folded into "babies delivered" style win totals.
//

import Foundation

nonisolated public enum JarCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case boy
    case girl
    case nurseCatch
    case remembrance

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .boy: String(localized: "Boy", bundle: .module)
        case .girl: String(localized: "Girl", bundle: .module)
        case .nurseCatch: String(localized: "Nurse catch", bundle: .module)
        case .remembrance: String(localized: "In remembrance", bundle: .module)
        }
    }
}

/// One marble: a baby plus the delivery context the jar needs.
nonisolated public struct JarMarble: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let category: JarCategory
    public let isCSection: Bool
    /// Marbles from the same multiple birth share a link ID (nil for singletons).
    public let linkID: UUID?
    public let sex: Sex
    public let nurseCatch: Bool

    public init(id: UUID, category: JarCategory, isCSection: Bool, linkID: UUID?, sex: Sex, nurseCatch: Bool) {
        self.id = id; self.category = category; self.isCSection = isCSection
        self.linkID = linkID; self.sex = sex; self.nurseCatch = nurseCatch
    }

    /// Remembrance wins over nurse catch, which wins over sex.
    public static func category(sex: Sex, nurseCatch: Bool) -> JarCategory {
        if sex == .loss { return .remembrance }
        if nurseCatch { return .nurseCatch }
        return sex == .male ? .boy : .girl
    }
}

/// Counts for the legend and share image. `delivered` excludes remembrance.
nonisolated public struct JarSummary: Equatable, Sendable {
    public var boy = 0
    public var girl = 0
    public var nurseCatch = 0
    public var remembrance = 0
    public var cSection = 0
    /// Marbles that belong to a twin/multiple birth (linked).
    public var multiples = 0

    public init() {}

    public init(marbles: [JarMarble]) {
        for m in marbles {
            switch m.category {
            case .boy: boy += 1
            case .girl: girl += 1
            case .nurseCatch: nurseCatch += 1
            case .remembrance: remembrance += 1
            }
            if m.isCSection { cSection += 1 }
            if m.linkID != nil { multiples += 1 }
        }
    }

    /// Live births only; remembrance is never counted here.
    public var delivered: Int { boy + girl + nurseCatch }
    public var total: Int { delivered + remembrance }

    public func count(for category: JarCategory) -> Int {
        switch category {
        case .boy: boy
        case .girl: girl
        case .nurseCatch: nurseCatch
        case .remembrance: remembrance
        }
    }
}
