//
//  MarbleViewModel.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/25/25.
//

import Foundation
import SwiftUI

class MarbleViewModel: ObservableObject {
    @Published var marbles: [Marble] = []
    @Published var pendingMarbles: [Marble] = []
    @Published var displayedBabyIDs: Set<String> = []
    @Published var isAddingMarbles: Bool = false
}
