//
//  AppStateManager.swift
//
//
//  Created by Nick Molargik on 3/14/25.
//

import Foundation
import SwiftUI
import StorkModel

public class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    @Published var errorMessage: String = ""
    @Published var currentAppScreen: AppScreen = .splash
    @Published var selectedTab: Tab = .home
    @Published var paywallPresented: Bool = false
    @Published var navigationPath: [Delivery] = []
    @Published var showingDeliveryAddition: Bool = false
    @Published var currentDate = Date()
    
    private init() {
        // private to enforce singleton usage
    }
    
    var dateFormatterMMMdhmmssa: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm:ss a" // Example: "Jan 24, 3:45:23 PM"
        return formatter.string(from: self.currentDate)
    }
    
    var dateFormatterMMMd: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.currentDate = Date()
        }
    }
    
    var currentWeekRange: String {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        
        return "\(dateFormatterMMMd.string(from: weekStart)) - \(dateFormatterMMMd.string(from: weekEnd))"
    }


}
