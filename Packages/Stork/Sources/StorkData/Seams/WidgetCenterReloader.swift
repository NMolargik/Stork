//
//  WidgetCenterReloader.swift
//  StorkData
//
//  The production `WidgetTimelineReloading` conformance over `WidgetCenter`.
//

import StorkCore
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetCenterReloader: WidgetTimelineReloading {
    public init() {}

    public func reloadTimelines(ofKind kind: String) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }

    public func reloadAllTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
