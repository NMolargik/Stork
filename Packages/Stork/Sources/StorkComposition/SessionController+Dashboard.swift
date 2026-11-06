//
//  SessionController+Dashboard.swift
//  StorkComposition
//
//  View-model factories for the Dashboard and Calendar.
//

import StorkFeatureDashboard

public extension SessionController {
    func makeDashboardModel() -> DashboardModel {
        DashboardModel(loadDeliveries: loadDeliveries, entitlement: entitlement)
    }

    func makeCalendarModel() -> CalendarModel {
        CalendarModel(loadDeliveries: loadDeliveries, entitlement: entitlement)
    }
}
