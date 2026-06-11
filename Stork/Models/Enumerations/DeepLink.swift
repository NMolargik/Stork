//
//  DeepLink.swift
//  Stork
//

import Foundation

/// Deep link actions that can be triggered from widgets or external URLs.
enum DeepLink: Equatable {
    case newDelivery
    case dashboard
    case deliveries
    case weeklyDeliveries
    case delivery(UUID)
    case settings

    /// Parses a `stork://` URL. Returns nil for unrecognized URLs.
    init?(url: URL) {
        guard url.scheme == "stork" else { return nil }

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
        case "settings":
            self = .settings
        default:
            return nil
        }
    }
}
