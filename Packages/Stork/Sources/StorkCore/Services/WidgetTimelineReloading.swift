//
//  WidgetTimelineReloading.swift
//  StorkCore
//
//  Seam over `WidgetCenter` so logic that refreshes widget timelines can be verified in
//  tests without WidgetKit. The concrete `WidgetCenter`-backed conformance lives in
//  `StorkData`; Core stays WidgetKit-free.
//

import Foundation

public protocol WidgetTimelineReloading {
    /// Reloads timelines for the given widget kind.
    func reloadTimelines(ofKind kind: String)

    /// Reloads every widget timeline.
    func reloadAllTimelines()
}
