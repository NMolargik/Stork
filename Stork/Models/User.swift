//
//  User.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var joinDate: String = User.dateFormatter.string(from: Date())

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(id: UUID = UUID(), joinDate: String = User.dateFormatter.string(from: Date())) {
        self.id = id
        self.joinDate = joinDate
    }

    public init() {
        self.id = UUID()
        self.joinDate = User.dateFormatter.string(from: Date())
    }

    // MARK: - Samples
    static let sample: User = User()
}
