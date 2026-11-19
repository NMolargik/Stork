//
//  WidgetStorkMark.swift
//  StorkWidgets
//
//  The Stork mark for widgets. Full colour in the normal rendering mode; in the accented and
//  vibrant modes (tinted Home Screen, every Lock Screen accessory) the system recolours the
//  whole view to one tint, so the mark switches to a single-colour jar silhouette, marked
//  accentable, rather than melting into a solid blob.
//

import SwiftUI
import WidgetKit
import StorkDesignSystem

struct WidgetStorkMark: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if renderingMode == .fullColor {
            StorkMark()
        } else {
            StorkMark(monochrome: true)
                .foregroundStyle(.primary)
                .widgetAccentable()
        }
    }
}
