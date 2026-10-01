//
//  DeepLink.swift
//  StorkCore
//
//  Deep-link actions triggered by widgets, App Intents, Home-screen quick actions, or
//  external `stork://` URLs. Parsing is pure and fully testable.
//

import Foundation

nonisolated public enum DeepLink: Equatable, Sendable {
    case newDelivery
    case dashboard
    case deliveries
    case weeklyDeliveries
    case delivery(UUID)
    case calendar
    case settings

    /// Parses a `stork://` URL. Returns `nil` for unrecognized URLs.
    public init?(url: URL) {
        guard url.scheme == AppURLScheme.scheme else { return nil }

        switch url.host {
        case "new-delivery":
            self = .newDelivery
        case "dashboard":
            self = .dashboard
        case "deliveries":
            self = url.pathComponents.contains("week") ? .weeklyDeliveries : .deliveries
        case "delivery":
            // stork://delivery/<uuid> — opens a specific delivery's detail.
            guard let component = url.pathComponents.dropFirst().first,
                  let id = UUID(uuidString: component) else { return nil }
            self = .delivery(id)
        case "calendar":
            self = .calendar
        case "settings":
            self = .settings
        default:
            return nil
        }
    }

    /// The tab a deep link should land on, if any.
    public var destinationTab: AppTab? {
        switch self {
        case .newDelivery, .dashboard:        .dashboard
        case .deliveries, .weeklyDeliveries, .delivery:  .list
        case .calendar:                       .calendar
        case .settings:                       .settings
        }
    }
}
