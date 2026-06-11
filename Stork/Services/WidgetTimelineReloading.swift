//
//  WidgetTimelineReloading.swift
//  Stork
//

import Foundation
import WidgetKit

/// Seam over `WidgetCenter` so logic that refreshes widget timelines can be
/// verified in tests without WidgetKit.
protocol WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String)
}

struct WidgetCenterReloader: WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
