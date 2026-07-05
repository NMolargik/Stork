//
//  StorkWidgetsBundle.swift
//  StorkWidgets
//
//  Created by Nick Molargik on 11/3/25.
//

import WidgetKit
import SwiftUI

@main
struct StorkWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        DeliveriesThisWeekWidget()
        CareerTotalWidget()
        QuickStartWidget()

        // Lock Screen Widgets (iOS 16+)
        LockScreenWeeklyWidget()
        CareerTotalLockScreenWidget()
    }
}
